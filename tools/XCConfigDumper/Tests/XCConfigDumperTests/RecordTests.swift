@testable import XCConfigDumperCore
import XCTest

final class RecordTests: XCTestCase {
    func testSimple() {
        let line = "a     bb ccc"
        XCTAssertEqual(Record(line: line).fields, [Field(rawValue: "a"), Field(rawValue: "bb"), Field(rawValue: "ccc")])
    }

    func testSingleQuoted() {
        let line = "a 'b b' 'c c    c'"
        XCTAssertEqual(Record(line: line).fields, [Field(rawValue: "a"), Field(rawValue: "b b"), Field(rawValue: "c c    c")])
    }

    func testDoubleleQuoted() {
        let line = "a \"b b\" \"c c    c\""
        XCTAssertEqual(Record(line: line).fields, [Field(rawValue: "a"), Field(rawValue: "b b"), Field(rawValue: "c c    c")])
    }

    func testMixed() {
        let line = "a \"b b\" 'c c    c' d\\ d '\t\t' ' '"
        XCTAssertEqual(Record(line: line).fields, [Field(rawValue: "a"), Field(rawValue: "b b"), Field(rawValue: "c c    c"), Field(rawValue: "d d"), Field(rawValue: "\t\t"), Field(rawValue: " ")])
    }

    static var allTests = [
        ("testSimple", testSimple),
        ("testSingleQuoted", testSingleQuoted),
    ]
}
