@testable import Core
import XCTest

final class KVLineValueTests: XCTestCase {
    func testQuotedParser() throws {
        let parser = KVBlockParser.ValueParser.QuotedStringParser()

        let data1 = "a\\\"b1j_kf3 👍"
        let source1 = DataSource("\(data1)\" \\ \n")
        let result1 = parser.parse(source1)

        XCTAssertEqual(result1, "a\"b1j_kf3 👍")

        let data2 = "af v\n"
        let source2 = DataSource("\(data2)\" \n")
        let result2 = parser.parse(source2)

        XCTAssertEqual(result2, nil)

        let data3 = " he\u{1b}llo\\n"
        let source3 = DataSource("\(data3)\"")
        let result3 = parser.parse(source3)

        XCTAssertEqual(result3, " hello\\n")
    }
}
