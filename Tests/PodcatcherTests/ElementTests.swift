import XCTest
@testable import Podcatcher

final class ElementTests: XCTestCase {
    
    func testElementRawValues() {
        XCTAssertEqual(Element.item.rawValue, "item")
        XCTAssertEqual(Element.title.rawValue, "title")
        XCTAssertEqual(Element.date.rawValue, "pubDate")
        XCTAssertEqual(Element.enclosure.rawValue, "enclosure")
    }
    
    func testElementInitializationFromString() {
        XCTAssertEqual(Element(rawValue: "item"), .item)
        XCTAssertEqual(Element(rawValue: "title"), .title)
        XCTAssertEqual(Element(rawValue: "pubDate"), .date)
        XCTAssertEqual(Element(rawValue: "enclosure"), .enclosure)
        XCTAssertNil(Element(rawValue: "unknown"))
    }
    
    func testElementCaseIterable() {
        let allElements = Element.allCases
        XCTAssertEqual(allElements.count, 4)
        XCTAssertTrue(allElements.contains(.item))
        XCTAssertTrue(allElements.contains(.title))
        XCTAssertTrue(allElements.contains(.date))
        XCTAssertTrue(allElements.contains(.enclosure))
    }
}