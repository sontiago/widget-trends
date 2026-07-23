import Foundation

/// Результат запроса трендов: данные и признак «из устаревшего кэша».
public struct TrendsResult: Sendable {
    public let snapshot: TrendsSnapshot
    public let isFromCache: Bool

    public init(snapshot: TrendsSnapshot, isFromCache: Bool) {
        self.snapshot = snapshot
        self.isFromCache = isFromCache
    }
}

/// Фасад для приложения и виджета: загрузка по (регион, окно) с сортировкой
/// по разделу, фолбэком на RSS при недоступности API и на кэш при отсутствии сети.
public struct TrendsService: Sendable {
    /// Кэш моложе этого возраста считается свежим — его можно показывать
    /// сразу, без сетевого запроса (мгновенная смена настроек виджета).
    public static let cacheFreshness: TimeInterval = 5 * 60
    /// Сколько элементов храним в кэше (до нарезки по разделу и лимиту).
    private static let storedLimit = 40

    private let apiClient: TrendingAPIClient
    private let rssClient: GoogleTrendsClient
    private let cache: TrendsCache

    public init(
        apiClient: TrendingAPIClient = TrendingAPIClient(),
        rssClient: GoogleTrendsClient = GoogleTrendsClient(),
        cache: TrendsCache = TrendsCache()
    ) {
        self.apiClient = apiClient
        self.rssClient = rssClient
        self.cache = cache
    }

    /// Кэшированный снимок (для мгновенного показа), если есть.
    public func cached(geos: [String], window: TrendsTimeWindow) -> TrendsSnapshot? {
        cache.load(geos: geos, window: window)
    }

    /// Загружает свежие тренды по списку стран; при сбое сети возвращает кэш
    /// (isFromCache = true). Если нет ни сети, ни кэша — пробрасывает ошибку.
    public func trends(
        for geos: [String],
        window: TrendsTimeWindow,
        section: TrendsSection,
        limit: Int = 20
    ) async throws -> TrendsResult {
        let geos = geos.isEmpty ? [TrendsCountry.fallback.code] : geos
        do {
            let items = try await fetchFresh(geos: geos, window: window)
            let snapshot = TrendsSnapshot(items: items, fetchedAt: Date())
            cache.save(snapshot, geos: geos, window: window)
            return TrendsResult(
                snapshot: sorted(snapshot, section: section, limit: limit),
                isFromCache: false
            )
        } catch {
            if let cached = cache.load(geos: geos, window: window) {
                return TrendsResult(
                    snapshot: sorted(cached, section: section, limit: limit),
                    isFromCache: true
                )
            }
            throw error
        }
    }

    /// Сортирует снимок по разделу и режет по лимиту.
    public func sorted(_ snapshot: TrendsSnapshot, section: TrendsSection, limit: Int) -> TrendsSnapshot {
        TrendsSnapshot(
            items: Array(Self.sort(snapshot.items, by: section).prefix(limit)),
            fetchedAt: snapshot.fetchedAt
        )
    }

    static func sort(_ items: [TrendItem], by section: TrendsSection) -> [TrendItem] {
        switch section {
        case .top:
            return items.sorted { lhs, rhs in
                if lhs.trafficValue != rhs.trafficValue { return lhs.trafficValue > rhs.trafficValue }
                return lhs.title < rhs.title
            }
        case .rising:
            return items.sorted { lhs, rhs in
                let lhsGrowth = lhs.growthPercent ?? 0
                let rhsGrowth = rhs.growthPercent ?? 0
                if lhsGrowth != rhsGrowth { return lhsGrowth > rhsGrowth }
                return lhs.trafficValue > rhs.trafficValue
            }
        }
    }

    /// Язык метаданных API — язык системы пользователя.
    private static var apiLanguage: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    private func fetchFresh(geos: [String], window: TrendsTimeWindow) async throws -> [TrendItem] {
        do {
            let feeds = try await fetchAll(geos: geos) { geo in
                try await apiClient.fetch(geo: geo, window: window, language: Self.apiLanguage)
            }
            return WorldAggregator.aggregate(feeds: feeds, limit: Self.storedLimit)
        } catch {
            // Аварийный фолбэк: RSS отдаёт только «топ за день» без роста,
            // но это лучше пустого виджета при поломке batchexecute.
            let feeds = try await fetchAll(geos: geos) { geo in
                try await rssClient.fetch(geo: geo)
            }
            return WorldAggregator.aggregate(feeds: feeds, limit: Self.storedLimit)
        }
    }

    private func fetchAll(
        geos: [String],
        using fetch: @escaping @Sendable (String) async throws -> [TrendItem]
    ) async throws -> [[TrendItem]] {
        try await withThrowingTaskGroup(of: [TrendItem].self) { group in
            for geo in geos {
                group.addTask { try await fetch(geo) }
            }
            var collected: [[TrendItem]] = []
            for try await feed in group {
                collected.append(feed)
            }
            return collected
        }
    }
}
