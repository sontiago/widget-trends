import XCTest
@testable import TrendsKit

final class TrendsFeedParserTests: XCTestCase {
    private func fixtureData() throws -> Data {
        let url = try XCTUnwrap(
            Bundle.module.url(forResource: "trends_ru", withExtension: "xml", subdirectory: "Fixtures")
        )
        return try Data(contentsOf: url)
    }

    func testParsesAllItems() throws {
        let items = try TrendsFeedParser.parse(data: fixtureData())
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].title, "погода тольятти")
        XCTAssertEqual(items[0].approxTraffic, "200+")
        XCTAssertEqual(items[0].trafficValue, 200)
        XCTAssertEqual(items[1].title, "роналдо")
        XCTAssertEqual(items[2].trafficValue, 1000)
    }

    func testParsesPubDate() throws {
        let items = try TrendsFeedParser.parse(data: fixtureData())
        let published = try XCTUnwrap(items[0].published)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: published)
        XCTAssertEqual(components.year, 2026)
        XCTAssertEqual(components.month, 7)
        XCTAssertEqual(components.day, 22)
        XCTAssertEqual(components.hour, 21) // 14:10 -0700 = 21:10 UTC
    }

    func testNewsItemTitleDoesNotLeakIntoTrendTitle() throws {
        let items = try TrendsFeedParser.parse(data: fixtureData())
        XCTAssertEqual(items[1].title, "роналдо")
    }

    func testMalformedXMLThrows() {
        let data = Data("not xml at all <".utf8)
        XCTAssertThrowsError(try TrendsFeedParser.parse(data: data))
    }

    func testEmptyChannelYieldsNoItems() throws {
        let xml = """
        <?xml version="1.0"?><rss version="2.0"><channel><title>Empty</title></channel></rss>
        """
        let items = try TrendsFeedParser.parse(data: Data(xml.utf8))
        XCTAssertTrue(items.isEmpty)
    }
}
