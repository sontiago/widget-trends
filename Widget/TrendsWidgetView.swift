import SwiftUI
import WidgetKit
import TrendsKit

struct TrendsWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TrendsEntry

    private static let brandGradient = LinearGradient(
        colors: [Color(red: 0.10, green: 0.38, blue: 0.95), Color(red: 0.42, green: 0.18, blue: 0.90)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private static let risingGradient = LinearGradient(
        colors: [Color(red: 0.95, green: 0.45, blue: 0.10), Color(red: 0.90, green: 0.15, blue: 0.35)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    private var accentGradient: LinearGradient {
        entry.section == .rising ? Self.risingGradient : Self.brandGradient
    }

    private var accentColor: Color {
        entry.section == .rising
            ? Color(red: 0.95, green: 0.45, blue: 0.10)
            : Color(red: 0.10, green: 0.38, blue: 0.95)
    }

    /// Количество строк подобрано под фактическую высоту семейств,
    /// чтобы контент не обрезался сверху и снизу.
    private var visibleCount: Int {
        switch family {
        case .systemSmall: return 3
        case .systemMedium: return 4
        default: return 9
        }
    }

    private var isSmall: Bool { family == .systemSmall }
    /// Показывать флаг у строки, когда в таблице смешаны несколько стран.
    private var showsRowFlags: Bool { entry.countries.count > 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: isSmall ? 4 : 5) {
            header
            if entry.items.isEmpty {
                emptyState
            } else {
                rows
                Spacer(minLength: 0)
                if entry.isFromCache, let fetchedAt = entry.fetchedAt {
                    staleFooter(fetchedAt: fetchedAt)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .fontDesign(.rounded)
        .containerBackground(for: .widget) {
            ZStack {
                Rectangle().fill(.background)
                accentGradient.opacity(0.07)
            }
        }
        .widgetURL(isSmall ? entry.items.first.map {
            $0.exploreURL(geo: entry.linkGeo)
        } : nil)
    }

    // MARK: - Шапка

    private var headerTitle: String {
        if entry.countries.count == 1, let country = entry.countries.first {
            return "\(country.flag) \(country.name)"
        }
        return entry.countries.prefix(5).map(\.flag).joined(separator: " ")
            + (entry.countries.count > 5 ? " +\(entry.countries.count - 5)" : "")
    }

    private var header: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(accentGradient)
                .frame(width: 18, height: 18)
                .overlay {
                    Image(systemName: entry.section == .rising ? "flame.fill" : "chart.line.uptrend.xyaxis")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            Text(headerTitle)
                .font(isSmall ? .caption.bold() : .subheadline.bold())
                .lineLimit(1)
            Spacer(minLength: 4)
            if !isSmall {
                Text(verbatim: "\(entry.section.displayName) · \(entry.window.displayName.lowercased())")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button(intent: RefreshTrendsIntent()) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Строки

    private var rows: some View {
        ForEach(Array(entry.items.prefix(visibleCount).enumerated()), id: \.element.id) { index, item in
            let row = HStack(spacing: 6) {
                rankBadge(index + 1)
                if showsRowFlags, let geo = item.geo {
                    Text(TrendsCountry(code: geo).flag)
                        .font(.caption2)
                }
                Text(item.title)
                    .font(isSmall ? .caption2 : .footnote.weight(.medium))
                    .lineLimit(1)
                Spacer(minLength: 4)
                if !isSmall {
                    metricChip(for: item)
                }
            }
            if isSmall {
                row
            } else {
                Link(destination: item.exploreURL(geo: item.geo ?? entry.linkGeo)) { row }
            }
        }
    }

    private func rankBadge(_ rank: Int) -> some View {
        let size: CGFloat = isSmall ? 14 : 16
        return Circle()
            .fill(rank <= 3 ? AnyShapeStyle(accentGradient) : AnyShapeStyle(.quaternary.opacity(0.5)))
            .frame(width: size, height: size)
            .overlay {
                Text("\(rank)")
                    .font(.system(size: size * 0.55, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(rank <= 3 ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
            }
    }

    @ViewBuilder
    private func metricChip(for item: TrendItem) -> some View {
        if entry.section == .rising, let growth = item.growthLabel {
            chip(text: growth, tint: .green)
        } else if let traffic = item.approxTraffic {
            chip(text: traffic, tint: accentColor)
        }
    }

    private func chip(text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption2.monospacedDigit().weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(tint.opacity(0.12), in: Capsule())
    }

    // MARK: - Состояния

    private var emptyState: some View {
        VStack(spacing: 6) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("No Data")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            if !isSmall {
                Button(intent: RefreshTrendsIntent()) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .font(.caption2.bold())
                }
                .buttonStyle(.bordered)
                .tint(accentColor)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func staleFooter(fetchedAt: Date) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.arrow.circlepath")
            Text("Data from \(fetchedAt, style: .time)")
        }
        .font(.caption2)
        .foregroundStyle(.orange)
    }
}
