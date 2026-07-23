import WidgetKit
import TrendsKit

struct TrendsEntry: TimelineEntry {
    let date: Date
    let countries: [TrendsCountry]
    let section: TrendsSection
    let window: TrendsTimeWindow
    let items: [TrendItem]
    /// Время фактического получения данных (для пометки «из кэша»).
    let fetchedAt: Date?
    let isFromCache: Bool

    var linkGeo: String { countries.first?.code ?? TrendsCountry.fallback.code }

    static func placeholder() -> TrendsEntry {
        TrendsEntry(
            date: Date(),
            countries: [.fallback],
            section: .top,
            window: .day,
            items: [
                TrendItem(title: String(localized: "dollar exchange rate"), volume: 10_000,
                          growthPercent: 300, published: nil, geo: "RU"),
                TrendItem(title: String(localized: "weather"), volume: 5_000,
                          growthPercent: 150, published: nil, geo: "RU"),
                TrendItem(title: String(localized: "sports news"), volume: 2_000,
                          growthPercent: 100, published: nil, geo: "RU")
            ],
            fetchedAt: Date(),
            isFromCache: false
        )
    }
}

struct TrendsTimelineProvider: AppIntentTimelineProvider {
    private let service = TrendsService()
    private static let widgetLimit = 20
    /// Сколько ждём сеть, прежде чем показать кэш: смена настроек
    /// не должна оставлять на экране старые данные дольше пары секунд.
    private static let networkGrace: TimeInterval = 5

    func placeholder(in context: Context) -> TrendsEntry {
        .placeholder()
    }

    func snapshot(for configuration: RegionConfigurationIntent, in context: Context) async -> TrendsEntry {
        if context.isPreview {
            return .placeholder()
        }
        return await makeEntry(configuration: configuration)
    }

    func timeline(for configuration: RegionConfigurationIntent, in context: Context) async -> Timeline<TrendsEntry> {
        let entry = await makeEntry(configuration: configuration)
        let interval: TimeInterval
        if entry.items.isEmpty {
            interval = 60 // нет ни сети, ни кэша — пробуем скоро
        } else if entry.isFromCache {
            interval = min(configuration.refresh.interval, 5 * 60) // показали кэш — дотянемся до сети раньше
        } else {
            interval = configuration.refresh.interval
        }
        return Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(interval)))
    }

    /// Стратегия: свежий кэш → мгновенно; иначе сеть с грейс-таймаутом,
    /// по его истечении — любой кэш; совсем ничего — пустое состояние.
    private func makeEntry(configuration: RegionConfigurationIntent) async -> TrendsEntry {
        let countries = configuration.selectedCountries
        let geos = countries.map(\.code)
        let window = configuration.window.timeWindow
        let section = configuration.section.section

        if let cached = service.cached(geos: geos, window: window),
           Date().timeIntervalSince(cached.fetchedAt) < TrendsService.cacheFreshness {
            let snapshot = service.sorted(cached, section: section, limit: Self.widgetLimit)
            return entry(countries: countries, section: section, window: window,
                         snapshot: snapshot, isFromCache: false)
        }

        if let result = await fetchWithTimeout(geos: geos, window: window, section: section) {
            return entry(countries: countries, section: section, window: window,
                         snapshot: result.snapshot, isFromCache: result.isFromCache)
        }

        if let cached = service.cached(geos: geos, window: window) {
            let snapshot = service.sorted(cached, section: section, limit: Self.widgetLimit)
            return entry(countries: countries, section: section, window: window,
                         snapshot: snapshot, isFromCache: true)
        }

        return TrendsEntry(date: Date(), countries: countries, section: section, window: window,
                           items: [], fetchedAt: nil, isFromCache: false)
    }

    private func fetchWithTimeout(
        geos: [String],
        window: TrendsTimeWindow,
        section: TrendsSection
    ) async -> TrendsResult? {
        await withTaskGroup(of: TrendsResult?.self) { group in
            group.addTask {
                try? await service.trends(for: geos, window: window, section: section, limit: Self.widgetLimit)
            }
            group.addTask {
                try? await Task.sleep(for: .seconds(Self.networkGrace))
                return nil
            }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }
    }

    private func entry(
        countries: [TrendsCountry],
        section: TrendsSection,
        window: TrendsTimeWindow,
        snapshot: TrendsSnapshot,
        isFromCache: Bool
    ) -> TrendsEntry {
        TrendsEntry(
            date: Date(),
            countries: countries,
            section: section,
            window: window,
            items: snapshot.items,
            fetchedAt: snapshot.fetchedAt,
            isFromCache: isFromCache
        )
    }
}
