import XCTest
@testable import TrendsKit

final class SectionSortTests: XCTestCase {
    private func item(_ title: String, volume: Int, growth: Int?) -> TrendItem {
        TrendItem(title: title, volume: volume, growthPercent: growth, published: nil)
    }

    func testTopSortsByVolume() {
        let sorted = TrendsService.sort([
            item("small", volume: 100, growth: 1000),
            item("big", volume: 50_000, growth: 100),
            item("mid", volume: 5_000, growth: 500)
        ], by: .top)
        XCTAssertEqual(sorted.map(\.title), ["big", "mid", "small"])
    }

    func testRisingSortsByGrowthThenVolume() {
        let sorted = TrendsService.sort([
            item("slow", volume: 100_000, growth: 100),
            item("fast", volume: 500, growth: 1000),
            item("fastButSmaller", volume: 200, growth: 1000),
            item("noGrowthData", volume: 900_000, growth: nil)
        ], by: .rising)
        XCTAssertEqual(sorted.map(\.title), ["fast", "fastButSmaller", "slow", "noGrowthData"])
    }

    func testVolumeFormatting() {
        XCTAssertEqual(TrendItem.format(volume: 500), "500+")
        XCTAssertEqual(TrendItem.format(volume: 1_000), "1K+")
        XCTAssertEqual(TrendItem.format(volume: 2_500), "2.5K+")
        XCTAssertEqual(TrendItem.format(volume: 100_000), "100K+")
        XCTAssertEqual(TrendItem.format(volume: 2_000_000), "2M+")
        XCTAssertNil(TrendItem.format(volume: 0))
    }

    func testCountryFlagsAndNames() {
        let russia = TrendsCountry(code: "RU")
        XCTAssertEqual(russia.flag, "🇷🇺")
        // Название локализовано под язык системы — сверяем с тем же источником.
        XCTAssertEqual(
            russia.name,
            Locale.autoupdatingCurrent.localizedString(forRegionCode: "RU") ?? "RU"
        )
        XCTAssertFalse(russia.name.isEmpty)
        XCTAssertNotEqual(russia.name, "RU")
        XCTAssertEqual(TrendsCountry(code: "us").code, "US")
        XCTAssertFalse(TrendsCountry.supported.isEmpty)
        XCTAssertTrue(TrendsCountry.supported.contains(TrendsCountry.fallback))
    }

    func testWindowHours() {
        XCTAssertEqual(TrendsTimeWindow.hour.hours, 1)
        XCTAssertEqual(TrendsTimeWindow.day.hours, 24)
        XCTAssertEqual(TrendsTimeWindow.week.hours, 168)
    }
}
