import Foundation

/// Страна Google Trends. Список отображаемых стран настраивается
/// пользователем; результаты выбранных стран сводятся в единую таблицу.
public struct TrendsCountry: Codable, Hashable, Sendable, Identifiable {
    public let code: String

    public var id: String { code }

    public init(code: String) {
        self.code = code.uppercased()
    }

    /// Флаг-эмодзи из ISO-кода (regional indicator symbols).
    public var flag: String {
        code.unicodeScalars
            .compactMap { UnicodeScalar(127_397 + $0.value) }
            .map(String.init)
            .joined()
    }

    /// Название страны на языке системы (следует за локалью пользователя).
    public var name: String {
        Locale.autoupdatingCurrent.localizedString(forRegionCode: code) ?? code
    }

    public static let fallback = TrendsCountry(code: "RU")

    /// Страны, доступные для выбора (гео с данными Google Trends).
    public static let supported: [TrendsCountry] = [
        "RU", "BY", "KZ", "UA", "TR",
        "US", "CA", "MX", "BR", "AR",
        "GB", "DE", "FR", "IT", "ES", "PL", "NL", "SE", "CH",
        "IL", "AE", "IN", "ID", "JP", "KR", "VN", "TH",
        "AU", "EG", "ZA"
    ].map(TrendsCountry.init)
}
