import AppIntents
import TrendsKit

/// Параметры меню «Редактировать виджет».
enum WindowOption: String, AppEnum {
    case hour, day, week

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Time Window")
    static let caseDisplayRepresentations: [WindowOption: DisplayRepresentation] = [
        .hour: DisplayRepresentation(title: "Hour"),
        .day: DisplayRepresentation(title: "Day"),
        .week: DisplayRepresentation(title: "Week")
    ]

    var timeWindow: TrendsTimeWindow {
        switch self {
        case .hour: return .hour
        case .day: return .day
        case .week: return .week
        }
    }
}

enum SectionOption: String, AppEnum {
    case top, rising

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Section")
    static let caseDisplayRepresentations: [SectionOption: DisplayRepresentation] = [
        .top: DisplayRepresentation(title: "Top"),
        .rising: DisplayRepresentation(title: "Rising")
    ]

    var section: TrendsSection {
        switch self {
        case .top: return .top
        case .rising: return .rising
        }
    }
}

enum RefreshOption: String, AppEnum {
    case minutes15, minutes30, minutes60

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Refresh Interval")
    static let caseDisplayRepresentations: [RefreshOption: DisplayRepresentation] = [
        .minutes15: DisplayRepresentation(title: "15 minutes"),
        .minutes30: DisplayRepresentation(title: "30 minutes"),
        .minutes60: DisplayRepresentation(title: "1 hour")
    ]

    var interval: TimeInterval {
        switch self {
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .minutes60: return 60 * 60
        }
    }
}

struct RegionConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Trends Configuration"
    static let description = IntentDescription("Countries, time window, section, and refresh rate.")

    @Parameter(title: "Countries")
    var countries: [CountryEntity]?

    @Parameter(title: "Time Window", default: .day)
    var window: WindowOption

    @Parameter(title: "Section", default: .top)
    var section: SectionOption

    @Parameter(title: "Refresh", default: .minutes30)
    var refresh: RefreshOption

    /// Выбранные страны с защитой от пустого списка.
    var selectedCountries: [TrendsCountry] {
        let selected = (countries ?? []).map(\.country)
        return selected.isEmpty ? [.fallback] : selected
    }
}
