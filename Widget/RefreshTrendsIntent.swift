import AppIntents
import WidgetKit

/// Кнопка «Обновить» в самом виджете: после perform() WidgetKit
/// перезагружает таймлайн — мгновенное обновление по клику.
struct RefreshTrendsIntent: AppIntent {
    static let title: LocalizedStringResource = "Refresh Trends"
    static let description = IntentDescription("Reloads the trends widget data.")

    func perform() async throws -> some IntentResult {
        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}
