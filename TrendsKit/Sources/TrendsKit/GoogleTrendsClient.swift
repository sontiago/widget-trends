import Foundation

/// Загружает RSS-фид Google Trends для одного гео. Только HTTPS.
public struct GoogleTrendsClient: Sendable {
    public enum ClientError: Error {
        case badResponse(statusCode: Int)
    }

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    static func feedURL(geo: String) -> URL {
        var components = URLComponents(string: "https://trends.google.com/trending/rss")!
        components.queryItems = [URLQueryItem(name: "geo", value: geo)]
        return components.url!
    }

    public func fetch(geo: String) async throws -> [TrendItem] {
        var request = URLRequest(url: Self.feedURL(geo: geo))
        request.timeoutInterval = 15
        request.setValue("TrendsWidget/1.0 (macOS)", forHTTPHeaderField: "User-Agent")
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw ClientError.badResponse(statusCode: http.statusCode)
        }
        return try TrendsFeedParser.parse(data: data).map { item in
            TrendItem(
                title: item.title,
                approxTraffic: item.approxTraffic,
                published: item.published,
                geo: geo
            )
        }
    }
}
