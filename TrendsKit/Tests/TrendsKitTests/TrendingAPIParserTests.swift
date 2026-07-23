import XCTest
@testable import TrendsKit

final class TrendingAPIParserTests: XCTestCase {
    /// Реалистичный ответ batchexecute: анти-JSON-префикс + конверт wrb.fr,
    /// внутри — JSON-строка с массивом трендов (индексы 0/3/6/8).
    private func makeResponse(payload: String) -> Data {
        let escaped = payload
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let body = """
        )]}'

        [["wrb.fr","i0OFE","\(escaped)",null,null,null,"generic"],["di",10],["af.httprm",10,"123",49]]
        """
        return Data(body.utf8)
    }

    func testParsesTrendEntries() throws {
        let payload = """
        [null,[["курс доллара",null,"RU",[1784745000],null,null,100000,null,1000,["курс доллара"],[17],[],"курс доллара"],\
        ["погода",null,"RU",[1784746200],null,null,500,null,600,["погода"],[4],[],"погода"]]]
        """
        let items = try TrendingAPIParser.parse(data: makeResponse(payload: payload))

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "курс доллара")
        XCTAssertEqual(items[0].trafficValue, 100_000)
        XCTAssertEqual(items[0].approxTraffic, "100K+")
        XCTAssertEqual(items[0].growthPercent, 1000)
        XCTAssertEqual(items[0].geo, "RU")
        XCTAssertEqual(items[0].published, Date(timeIntervalSince1970: 1_784_745_000))
        XCTAssertEqual(items[1].growthLabel, "+600%")
    }

    func testEmptyTrendListYieldsNoItems() throws {
        let items = try TrendingAPIParser.parse(data: makeResponse(payload: "[null,[]]"))
        XCTAssertTrue(items.isEmpty)
    }

    func testErrorEnvelopeThrows() {
        let body = """
        )]}'

        [["wrb.fr","i0OFE",null,null,null,[13],"generic"],["di",10]]
        """
        XCTAssertThrowsError(try TrendingAPIParser.parse(data: Data(body.utf8)))
    }

    func testGarbageThrows() {
        XCTAssertThrowsError(try TrendingAPIParser.parse(data: Data("no json here".utf8)))
    }

    func testRequestBodyIsFormEncoded() {
        let body = TrendingAPIClient.body(geo: "RU", window: .day, language: "ru")
        let text = String(data: body, encoding: .utf8)!
        XCTAssertTrue(text.hasPrefix("f.req="))
        XCTAssertFalse(text.contains("\""), "кавычки должны быть percent-encoded")
        let decoded = text.removingPercentEncoding!
        XCTAssertTrue(decoded.contains(#""i0OFE""#))
        XCTAssertTrue(decoded.contains(#"\"RU\""#))
        XCTAssertTrue(decoded.contains("24"))
    }
}
