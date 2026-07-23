import Foundation

/// Клиент внутреннего API Google Trends «Trending Now» (batchexecute/i0OFE).
/// Единственный источник, отдающий окна времени и процент роста. Только HTTPS.
public struct TrendingAPIClient: Sendable {
    public enum ClientError: Error {
        case badResponse(statusCode: Int)
    }

    private static let endpoint = URL(string: "https://trends.google.com/_/TrendsUi/data/batchexecute")!
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(geo: String, window: TrendsTimeWindow, language: String) async throws -> [TrendItem] {
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 15
        request.setValue(
            "application/x-www-form-urlencoded;charset=UTF-8",
            forHTTPHeaderField: "Content-Type"
        )
        request.httpBody = Self.body(geo: geo, window: window, language: language)

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientError.badResponse(statusCode: http.statusCode)
        }
        return try TrendingAPIParser.parse(data: data)
    }

    /// Тело запроса: f.req=[[["i0OFE","[null,null,\"RU\",0,\"ru\",24,1]",null,"generic"]]]
    static func body(geo: String, window: TrendsTimeWindow, language: String) -> Data {
        let inner = "[null,null,\"\(geo)\",0,\"\(language)\",\(window.hours),1]"
        let outer: [[[Any]]] = [[["i0OFE", inner, NSNull(), "generic"]]]
        // Массив верхнего уровня всегда сериализуем — form-encode и отправляем.
        let json = String(
            data: (try? JSONSerialization.data(withJSONObject: outer)) ?? Data("[]".utf8),
            encoding: .utf8
        ) ?? "[]"
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._")
        let encoded = json.addingPercentEncoding(withAllowedCharacters: allowed) ?? json
        return Data("f.req=\(encoded)".utf8)
    }
}
