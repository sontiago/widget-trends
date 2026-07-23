import Foundation

/// Один поисковый тренд.
public struct TrendItem: Codable, Equatable, Sendable, Identifiable {
    public var id: String { title.lowercased() }

    /// Поисковый запрос, например «погода тольятти».
    public let title: String
    /// Отображаемый объём поиска, например «500+» или «100K+».
    public let approxTraffic: String?
    /// Числовое значение объёма для сортировки раздела «Топ».
    public let trafficValue: Int
    /// Процент роста популярности (для раздела «Райзинг»); nil у RSS-фолбэка.
    public let growthPercent: Int?
    /// Время старта/публикации тренда.
    public let published: Date?
    /// Гео-код страны, из которой пришёл тренд (для единой таблицы).
    public let geo: String?

    /// Элемент из RSS-фида (объём приходит строкой вида «500+»).
    public init(title: String, approxTraffic: String?, published: Date?, geo: String? = nil) {
        self.title = title
        self.approxTraffic = approxTraffic
        self.trafficValue = TrendItem.parseTraffic(approxTraffic)
        self.growthPercent = nil
        self.published = published
        self.geo = geo
    }

    /// Элемент из API «Trending Now» (объём и рост приходят числами).
    public init(title: String, volume: Int, growthPercent: Int?, published: Date?, geo: String? = nil) {
        self.title = title
        self.trafficValue = volume
        self.approxTraffic = TrendItem.format(volume: volume)
        self.growthPercent = growthPercent
        self.published = published
        self.geo = geo
    }

    /// Отображаемый рост: «+900%».
    public var growthLabel: String? {
        growthPercent.map { "+\($0)%" }
    }

    /// Ссылка на страницу тренда в Google Trends для заданного гео.
    public func exploreURL(geo: String) -> URL {
        var components = URLComponents(string: "https://trends.google.com/trends/explore")!
        components.queryItems = [
            URLQueryItem(name: "q", value: title),
            URLQueryItem(name: "geo", value: geo)
        ]
        return components.url!
    }

    /// Разбирает «500+», «1 000+», «2M+», «50K+» в число. Неизвестный формат — 0.
    static func parseTraffic(_ raw: String?) -> Int {
        guard let raw else { return 0 }
        let cleaned = raw.uppercased()
            .replacingOccurrences(of: "[+,.\\s\u{00A0}\u{202F}]", with: "", options: .regularExpression)
        var multiplier = 1
        var digits = cleaned
        if cleaned.hasSuffix("M") {
            multiplier = 1_000_000
            digits = String(cleaned.dropLast())
        } else if cleaned.hasSuffix("K") {
            multiplier = 1_000
            digits = String(cleaned.dropLast())
        }
        return (Int(digits) ?? 0) * multiplier
    }

    /// Форматирует 100000 → «100K+», 2000000 → «2M+», 500 → «500+».
    static func format(volume: Int) -> String? {
        guard volume > 0 else { return nil }
        func trimmed(_ value: Double) -> String {
            let rounded = (value * 10).rounded() / 10
            return rounded == rounded.rounded()
                ? String(Int(rounded))
                : String(rounded)
        }
        if volume >= 1_000_000 { return "\(trimmed(Double(volume) / 1_000_000))M+" }
        if volume >= 1_000 { return "\(trimmed(Double(volume) / 1_000))K+" }
        return "\(volume)+"
    }
}
