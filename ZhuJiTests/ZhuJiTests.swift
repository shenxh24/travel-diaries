import XCTest
@testable import ZhuJi

final class ZhuJiTests: XCTestCase {
    func testCategoriesAreStable() {
        XCTAssertEqual(PlaceCategory.allCases.map(\.rawValue), ["美食", "景点", "城市", "购物"])
    }
    func testCheckInDefaults() {
        let item = CheckIn(latitude: 31.2304, longitude: 121.4737)
        XCTAssertEqual(item.category, .sightseeing)
        XCTAssertEqual(item.title, "新的足迹")
    }
}

