@testable import Core
import XCTest

final class KVLineValueTests: XCTestCase {
    func testQuotedParser() throws {
        let parser = KVBlockParser.ValueParser.QuotedStringParser()

        let data1 = DataSource("\"a\\\"b1j_kf3 👍\" \\ \n")
        let result1 = parser.parse(data1)

        XCTAssertEqual(result1, .withSuccess(result: "a\"b1j_kf3 👍", warnings: []))

        let data2 = DataSource("\"af v\n\" \n")
        let result2 = parser.parse(data2)

        XCTAssertEqual(result2, .withErrors(result: "af v", warnings: [], errors: [
            .init(message: "New lines are not allowed inside the quoted strings", line: 1, col: 6),
        ]))

        let data3 = DataSource("_\" he\u{1b}llo\\n\"")
        data3.nextPos()
        let result3 = parser.parse(data3)

        XCTAssertEqual(result3, .withSuccess(result: " hello\\n", warnings: [
            .init(message: "Control characters were detected and skipped in the quoted string", line: 1, col: 2),
        ]))

        let data4 = DataSource("\"hello\"-")
        let result4 = parser.parse(data4)

        XCTAssertEqual(result4, .withSuccess(result: "hello", warnings: []))
        XCTAssertEqual(data4.currentCol, 7)
        XCTAssertEqual(data4.currentCharacter, "\"")

        let data5 = DataSource("\"hello")
        let result5 = parser.parse(data5)

        XCTAssertEqual(result5, .withErrors(result: "hello", warnings: [], errors: [
            .init(message: "End of stream is encountered before the end of quoted string", line: 1, col: 1),
        ]))

        let data6 = DataSource("_\"hello\"  \n    \"su\u{1b}\u{1b}per")

        data6.nextPos()
        let result6A = parser.parse(data6)

        XCTAssertEqual(result6A, .withSuccess(result: "hello", warnings: []))
        XCTAssertEqual(data6.currentCol, 8)
        XCTAssertEqual(data6.currentLine, 1)
        XCTAssertEqual(data6.currentCharacter, "\"")

        data6.skipLine()
        data6.skipWhiteSpaces()
        let result6B = parser.parse(data6)

        XCTAssertEqual(result6B, .withErrors(result: "super", warnings: [
            .init(message: "Control characters were detected and skipped in the quoted string", line: 2, col: 5),
        ], errors: [
            .init(message: "End of stream is encountered before the end of quoted string", line: 2, col: 5),
        ]))
        XCTAssertEqual(data6.currentCol, 13)
        XCTAssertEqual(data6.currentLine, 2)
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
        let data12 = DataSource("18 // a comment")

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
        let result12 = parser.parse(data12, firstCharacter: .digit("1"))

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
        XCTAssertEqual(result12, .integer(18))

        XCTAssertEqual(data12.currentCol, 3)
        XCTAssertEqual(data12.currentCharacter, " ")
    }

    func testBoolParser() throws {
        let parser = KVBlockParser.ValueParser.BoolParser()

        let data1 = DataSource("true")
        let data2 = DataSource("false // true")
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

        XCTAssertEqual(data2.currentCol, 6)
        XCTAssertEqual(data2.currentCharacter, " ")
    }

    func testEnvParser() throws {
        let parser = KVBlockParser.ValueParser.EnvParser()

        let data1 = DataSource("env(  \"yes?\" )")
        let data2 = DataSource("env(\"no 12\") // is this a comment? \n")
        let data3 = DataSource("env( \"\\\"\")// no?")
        let data4 = DataSource("env(\"\")\n")
        let data5 = DataSource("enve(\"1\") ")
        let data6 = DataSource("env(\"--\")- ")

        let result1 = parser.parse(data1)
        let result2 = parser.parse(data2)
        let result3 = parser.parse(data3)
        let result4 = parser.parse(data4)
        let result5 = parser.parse(data5)
        let result6 = parser.parse(data6)

        XCTAssertEqual(result1, "yes?")
        XCTAssertEqual(result2, "no 12")
        XCTAssertEqual(result3, "\"")
        XCTAssertEqual(result4, "")
        XCTAssertEqual(result5, nil)
        XCTAssertEqual(result6, nil)

        XCTAssertEqual(data2.currentCol, 13)
        XCTAssertEqual(data2.currentCharacter, " ")
    }
}
