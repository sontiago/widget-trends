import XCTest
@testable import TrendsKit

final class WorldAggregatorTests: XCTestCase {
    private func item(_ title: String, _ traffic: String) -> TrendItem {
        TrendItem(title: title, approxTraffic: traffic, published: nil)
    }

    func testDeduplicatesCaseInsensitivelyKeepingMaxTraffic() {
        let feedA = [item("Messi", "500+"), item("weather", "200+")]
        let feedB = [item("messi", "2K+"), item("bitcoin", "1K+")]
        let result = WorldAggregator.aggregate(feeds: [feedA, feedB])

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].title, "messi")
        XCTAssertEqual(result[0].trafficValue, 2000)
    }

    func testSortsByTrafficDescending() {
        let result = WorldAggregator.aggregate(feeds: [
            [item("a", "100+"), item("b", "5K+"), item("c", "1K+")]
        ])
        XCTAssertEqual(result.map(\.title), ["b", "c", "a"])
    }

    func testRespectsLimit() {
        let feed = (1...30).map { item("query\($0)", "\($0)+") }
        let result = WorldAggregator.aggregate(feeds: [feed], limit: 10)
        XCTAssertEqual(result.count, 10)
        XCTAssertEqual(result[0].trafficValue, 30)
    }

    func testEmptyFeeds() {
        XCTAssertTrue(WorldAggregator.aggregate(feeds: []).isEmpty)
        XCTAssertTrue(WorldAggregator.aggregate(feeds: [[], []]).isEmpty)
    }
}
