import Foundation

/// Окно времени для трендов. «Месяц» источником не поддерживается
/// (максимум 7 дней, проверено 2026-07-23 — окно 720 ч API отклоняет).
public enum TrendsTimeWindow: String, Codable, CaseIterable, Sendable {
    case hour
    case day
    case week

    public var hours: Int {
        switch self {
        case .hour: return 1
        case .day: return 24
        case .week: return 168
        }
    }

    public var displayName: String {
        switch self {
        case .hour: return String(localized: "Hour", bundle: .module)
        case .day: return String(localized: "Day", bundle: .module)
        case .week: return String(localized: "Week", bundle: .module)
        }
    }
}

/// Раздел выдачи: топ по объёму или набирающие популярность.
public enum TrendsSection: String, Codable, CaseIterable, Sendable {
    case top
    case rising

    public var displayName: String {
        switch self {
        case .top: return String(localized: "Top", bundle: .module)
        case .rising: return String(localized: "Rising", bundle: .module)
        }
    }
}
