import XCTest
@testable import TrendsKit

final class TrafficParsingTests: XCTestCase {
    func testPlainNumbers() {
        XCTAssertEqual(TrendItem.parseTraffic("200+"), 200)
        XCTAssertEqual(TrendItem.parseTraffic("1,000+"), 1000)
        XCTAssertEqual(TrendItem.parseTraffic("50,000+"), 50_000)
    }

    func testSpacesIncludingNonBreaking() {
        XCTAssertEqual(TrendItem.parseTraffic("1 000+"), 1000)
        XCTAssertEqual(TrendItem.parseTraffic("1\u{00A0}000+"), 1000)
        XCTAssertEqual(TrendItem.parseTraffic("1\u{202F}000+"), 1000)
    }

    func testSuffixMultipliers() {
        XCTAssertEqual(TrendItem.parseTraffic("50K+"), 50_000)
        XCTAssertEqual(TrendItem.parseTraffic("2M+"), 2_000_000)
        XCTAssertEqual(TrendItem.parseTraffic("2m+"), 2_000_000)
    }

    func testUnknownFormatsFallBackToZero() {
        XCTAssertEqual(TrendItem.parseTraffic(nil), 0)
        XCTAssertEqual(TrendItem.parseTraffic(""), 0)
        XCTAssertEqual(TrendItem.parseTraffic("много"), 0)
    }
}
