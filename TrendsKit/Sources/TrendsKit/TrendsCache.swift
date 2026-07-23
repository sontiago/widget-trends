import Foundation

/// Снимок трендов с моментом получения. Хранится без сортировки по разделу —
/// «Топ»/«Райзинг» это разные сортировки одних и тех же данных.
public struct TrendsSnapshot: Codable, Equatable, Sendable {
    public let items: [TrendItem]
    public let fetchedAt: Date

    public init(items: [TrendItem], fetchedAt: Date) {
        self.items = items
        self.fetchedAt = fetchedAt
    }
}

/// Кэш последнего успешного ответа по (регион, окно) — фолбэк при отсутствии
/// сети и источник мгновенного показа при смене настроек виджета.
/// @unchecked: UserDefaults потокобезопасен, но не помечен Sendable в SDK.
public struct TrendsCache: @unchecked Sendable {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(geos: [String], window: TrendsTimeWindow) -> String {
        "trends.cache.v3.\(geos.map { $0.uppercased() }.sorted().joined(separator: "-")).\(window.rawValue)"
    }

    public func load(geos: [String], window: TrendsTimeWindow) -> TrendsSnapshot? {
        guard let data = defaults.data(forKey: key(geos: geos, window: window)) else { return nil }
        return try? JSONDecoder().decode(TrendsSnapshot.self, from: data)
    }

    public func save(_ snapshot: TrendsSnapshot, geos: [String], window: TrendsTimeWindow) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key(geos: geos, window: window))
    }
}
