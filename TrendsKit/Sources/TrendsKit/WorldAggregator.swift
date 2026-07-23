import Foundation

/// Собирает «мировой» топ из нескольких региональных фидов:
/// дедупликация по запросу (без учёта регистра), у дубликатов берётся
/// максимальный трафик, сортировка по трафику по убыванию.
public enum WorldAggregator {
    public static func aggregate(feeds: [[TrendItem]], limit: Int = 20) -> [TrendItem] {
        var best: [String: TrendItem] = [:]
        for feed in feeds {
            for item in feed {
                let key = item.title.lowercased()
                if let existing = best[key], existing.trafficValue >= item.trafficValue {
                    continue
                }
                best[key] = item
            }
        }
        return Array(
            best.values
                .sorted { lhs, rhs in
                    if lhs.trafficValue != rhs.trafficValue {
                        return lhs.trafficValue > rhs.trafficValue
                    }
                    return lhs.title < rhs.title
                }
                .prefix(limit)
        )
    }
}
