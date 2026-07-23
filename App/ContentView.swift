import SwiftUI
import WidgetKit
import TrendsKit

struct ContentView: View {
    @AppStorage("selectedCountries") private var storedCountries = "RU"
    @State private var window: TrendsTimeWindow = .day
    @State private var section: TrendsSection = .top
    @State private var result: TrendsResult?
    @State private var errorMessage: String?
    @State private var isLoading = false

    private let service = TrendsService()

    private var selectedCodes: [String] {
        storedCountries.split(separator: ",").map(String.init).filter { !$0.isEmpty }
    }

    private var selectedCountries: [TrendsCountry] {
        let codes = selectedCodes
        return codes.isEmpty ? [.fallback] : codes.map(TrendsCountry.init)
    }

    private struct Query: Equatable {
        let codes: String
        let window: TrendsTimeWindow
        let section: TrendsSection
    }

    private struct Row: Identifiable {
        let id: String
        let rank: Int
        let item: TrendItem
    }

    private var rows: [Row] {
        guard let result else { return [] }
        return result.snapshot.items.enumerated().map { index, item in
            Row(id: item.id, rank: index + 1, item: item)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            controls
            table
            if let result, result.isFromCache {
                Label("Offline — data from \(result.snapshot.fetchedAt.formatted(date: .omitted, time: .shortened))",
                      systemImage: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Label("How to Add the Widget", systemImage: "plus.square.on.square")
                    .font(.headline)
                // Один литерал = один ключ локализации, поэтому не дробим.
                // swiftlint:disable:next line_length
                Text("Click the date in the menu bar → “Edit Widgets” → find “Trends”. Countries, time window, and section are configured via “Edit Widget”.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .task(id: Query(codes: storedCountries, window: window, section: section)) { await load() }
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await load() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(isLoading)
            }
        }
        .navigationTitle("Trends")
    }

    // MARK: - Управление (все параметры — dropdown)

    private var controls: some View {
        HStack(spacing: 10) {
            countriesMenu

            Picker("Section", selection: $section) {
                ForEach(TrendsSection.allCases, id: \.self) { section in
                    Text(section.displayName).tag(section)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Picker("Time Window", selection: $window) {
                ForEach(TrendsTimeWindow.allCases, id: \.self) { window in
                    Text(window.displayName).tag(window)
                }
            }
            .pickerStyle(.menu)
            .fixedSize()

            Spacer()
            if isLoading { ProgressView().controlSize(.small) }
        }
    }

    private var countriesLabel: String {
        let countries = selectedCountries
        if countries.count == 1 {
            return "\(countries[0].flag) \(countries[0].name)"
        }
        return countries.prefix(6).map(\.flag).joined(separator: " ")
            + (countries.count > 6 ? " +\(countries.count - 6)" : "")
    }

    private var countriesMenu: some View {
        Menu {
            ForEach(TrendsCountry.supported) { country in
                Button {
                    toggle(country)
                } label: {
                    if selectedCodes.contains(country.code) {
                        Label("\(country.flag) \(country.name)", systemImage: "checkmark")
                    } else {
                        Text("\(country.flag) \(country.name)")
                    }
                }
            }
            Divider()
            Button("Reset (Russia only)") { storedCountries = "RU" }
        } label: {
            Label(countriesLabel, systemImage: "globe")
        }
        .menuStyle(.borderedButton)
        .fixedSize()
    }

    private func toggle(_ country: TrendsCountry) {
        var codes = selectedCodes
        if let index = codes.firstIndex(of: country.code) {
            codes.remove(at: index)
        } else {
            codes.append(country.code)
        }
        storedCountries = codes.joined(separator: ",")
    }

    // MARK: - Единая таблица

    @ViewBuilder
    private var table: some View {
        if rows.isEmpty && !isLoading, let errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "wifi.slash").font(.largeTitle).foregroundStyle(.secondary)
                Text("Couldn’t Load Trends").font(.headline)
                Text(errorMessage).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Table(rows) {
                TableColumn("#") { row in
                    Text("\(row.rank)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .width(28)

                TableColumn("Country") { row in
                    let country = row.item.geo.map(TrendsCountry.init)
                    Text("\(country?.flag ?? "–") \(country?.code ?? "")")
                }
                .width(64)

                TableColumn("Query") { row in
                    Link(row.item.title,
                         destination: row.item.exploreURL(geo: row.item.geo ?? selectedCountries[0].code))
                }

                TableColumn("Volume") { row in
                    Text(row.item.approxTraffic ?? "—")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .width(70)

                TableColumn("Growth") { row in
                    Text(row.item.growthLabel ?? "—")
                        .monospacedDigit()
                        .bold()
                        .foregroundStyle(.green)
                }
                .width(70)
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            result = try await service.trends(
                for: selectedCountries.map(\.code),
                window: window,
                section: section,
                limit: 30
            )
            errorMessage = nil
            // Приложение и виджет живут в разных процессах: после загрузки
            // подталкиваем виджеты перечитать таймлайны (обход бага macOS,
            // когда смена конфигурации не перерисовывает виджет).
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            result = nil
            errorMessage = error.localizedDescription
        }
    }
}
