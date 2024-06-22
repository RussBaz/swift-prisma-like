@testable import Core
import XCTest

final class KVLineValueTests: XCTestCase {
    func testQuotedParser() throws {
        let parser = KVBlockParser.ValueParser.QuotedStringParser()

        let data1 = "a\\\"b1j_kf3 👍"
        let source1 = DataSource("\"\(data1)\" \\ \n")
        let result1 = parser.parse(source1)

        XCTAssertEqual(result1, "a\"b1j_kf3 👍")

        let data2 = "af v\n"
        let source2 = DataSource("\(data2)\" \n")
        let result2 = parser.parse(source2)

        XCTAssertEqual(result2, nil)

        let data3 = "\" he\u{1b}llo\\n"
        let source3 = DataSource("\(data3)\"")
        let result3 = parser.parse(source3)

        XCTAssertEqual(result3, " hello\\n")
    }

    func testNumberParser() throws {
        let parser = KVBlockParser.ValueParser.NumberParser()

        let data1 = DataSource("-123")
        let data2 = DataSource("3")
        let data3 = DataSource("+10.010")
        let data4 = DataSource("10.")
        let data5 = DataSource("+1")
        let data6 = DataSource("0100")
        let data7 = DataSource("-10.2 hello")
        let data8 = DataSource("10// no")
        let data9 = DataSource("10e1")
        let data10 = DataSource("10no //")
        let data11 = DataSource("-964.0\n 2 ")

        let result1 = parser.parse(data1, firstCharacter: .minus)
        let result2 = parser.parse(data2, firstCharacter: .digit("3"))
        let result3 = parser.parse(data3, firstCharacter: .plus)
        let result4 = parser.parse(data4, firstCharacter: .digit("1"))
        let result5 = parser.parse(data5, firstCharacter: .plus)
        let result6 = parser.parse(data6, firstCharacter: .digit("0"))
        let result7 = parser.parse(data7, firstCharacter: .minus)
        let result8 = parser.parse(data8, firstCharacter: .digit("1"))
        let result9 = parser.parse(data9, firstCharacter: .digit("1"))
        let result10 = parser.parse(data10, firstCharacter: .digit("1"))
        let result11 = parser.parse(data11, firstCharacter: .minus)

        XCTAssertEqual(result1, .integer(-123))
        XCTAssertEqual(result2, .integer(3))
        XCTAssertEqual(result3, .double(10.01))
        XCTAssertEqual(result4, .double(10))
        XCTAssertEqual(result5, .integer(1))
        XCTAssertEqual(result6, .integer(100))
        XCTAssertEqual(result7, .double(-10.2))
        XCTAssertEqual(result8, .integer(10))
        XCTAssertEqual(result9, nil)
        XCTAssertEqual(result10, nil)
        XCTAssertEqual(result11, .double(-964))
    }

    func testBoolParser() throws {
        let parser = KVBlockParser.ValueParser.BoolParser()

        let data1 = DataSource("true")
        let data2 = DataSource("false ")
        let data3 = DataSource("tRuE\n")
        let data4 = DataSource("FALSE/")
        let data5 = DataSource("tru ")
        let data6 = DataSource("false- ")

        let result1 = parser.parse(data1, firstCharacter: .t)
        let result2 = parser.parse(data2, firstCharacter: .f)
        let result3 = parser.parse(data3, firstCharacter: .t)
        let result4 = parser.parse(data4, firstCharacter: .f)
        let result5 = parser.parse(data5, firstCharacter: .t)
        let result6 = parser.parse(data6, firstCharacter: .f)

        XCTAssertEqual(result1, true)
        XCTAssertEqual(result2, false)
        XCTAssertEqual(result3, true)
        XCTAssertEqual(result4, false)
        XCTAssertEqual(result5, nil)
        XCTAssertEqual(result6, nil)
    }
}
