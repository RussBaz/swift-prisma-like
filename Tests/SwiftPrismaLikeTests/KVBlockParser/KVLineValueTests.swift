@testable import Core
import XCTest

final class KVLineValueTests: XCTestCase {
    func testQuotedParser() throws {
        typealias Parser = KVBlock.Parser.ValueParser.QuotedStringParser
        typealias Problem = KVBlock.Parser.ValueParser.QuotedStringParser.Problem

        let data1 = DataSource("\"a\\\"b1j_kf3 👍\" \\ \n")
        let data2 = DataSource("\"af v\n\" \n")
        let data3 = DataSource("_\" he\u{1b}llo\\n\"")
        data3.nextPos()
        let data4 = DataSource("\"hello\"-")
        let data5 = DataSource("\"hello")
        let data6 = DataSource("_\"hello\"  \n    \"su\u{1b}\u{1b}per")
        data6.nextPos()
        let data7 = DataSource("\" he\u{1b}llo \n\" ")
        let data8 = DataSource("\"test\"\n")

        let result1 = Parser.parse(data1)
        let result2 = Parser.parse(data2)
        let result3 = Parser.parse(data3)
        let result4 = Parser.parse(data4)
        let result5 = Parser.parse(data5)

        let result6A = Parser.parse(data6)

        XCTAssertEqual(data6.currentCol, 9)
        XCTAssertEqual(data6.currentLine, 1)
        XCTAssertEqual(data6.currentCharacter, " ")

        data6.skipLine()
        data6.skipWhiteSpaces()
        let result6B = Parser.parse(data6)
        let result7 = Parser.parse(data7)
        let result8 = Parser.parse(data8)

        XCTAssertEqual(result1, .withSuccess(result: "a\"b1j_kf3 👍", messages: []))
        XCTAssertEqual(result2, .withErrors(messages: [
            Problem.newLine.reference(line: 1, col: 6, level: .error),
        ]))
        XCTAssertEqual(result3, .withSuccess(result: " hello\\n", messages: [
            Problem.controlCharacter.reference(line: 1, col: 2, level: .warning),
        ]))
        XCTAssertEqual(result4, .withSuccess(result: "hello", messages: []))
        XCTAssertEqual(data4.currentCol, 8)
        XCTAssertEqual(data4.currentCharacter, "-")

        XCTAssertEqual(result5, .withErrors(messages: [
            Problem.endOfStream.reference(line: 1, col: 7, level: .error),
        ]))

        XCTAssertEqual(result6A, .withSuccess(result: "hello", messages: []))
        XCTAssertEqual(result6B, .withErrors(messages: [
            Problem.controlCharacter.reference(line: 2, col: 5, level: .warning),
            Problem.endOfStream.reference(line: 2, col: 13, level: .error),
        ]))
        XCTAssertEqual(data6.currentCol, 13)
        XCTAssertEqual(data6.currentLine, 2)

        XCTAssertEqual(result7, .withErrors(messages: [
            Problem.controlCharacter.reference(line: 1, col: 1, level: .warning),
            Problem.newLine.reference(line: 1, col: 10, level: .error),
        ]))

        XCTAssertEqual(result8, .withSuccess(result: "test", messages: []))
        XCTAssertEqual(data8.currentCol, 7)
        XCTAssertEqual(data8.currentLine, 1)
    }

    func testNumberParser() throws {
        typealias Parser = KVBlock.Parser.ValueParser.NumberParser
        typealias Problem = KVBlock.Parser.ValueParser.NumberParser.Problem

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
        let data13 = DataSource("+")
        let data14 = DataSource("-.1")
        let data15 = DataSource(".2 ")

        let result1 = Parser.parse(data1, firstCharacter: .minus)
        let result2 = Parser.parse(data2, firstCharacter: .digit("3"))
        let result3 = Parser.parse(data3, firstCharacter: .plus)
        let result4 = Parser.parse(data4, firstCharacter: .digit("1"))
        let result5 = Parser.parse(data5, firstCharacter: .plus)
        let result6 = Parser.parse(data6, firstCharacter: .digit("0"))
        let result7 = Parser.parse(data7, firstCharacter: .minus)
        let result8 = Parser.parse(data8, firstCharacter: .digit("1"))
        let result9 = Parser.parse(data9, firstCharacter: .digit("1"))
        let result10 = Parser.parse(data10, firstCharacter: .digit("1"))
        let result11 = Parser.parse(data11, firstCharacter: .minus)
        let result12 = Parser.parse(data12, firstCharacter: .digit("1"))
        let result13 = Parser.parse(data13, firstCharacter: .plus)
        let result14 = Parser.parse(data14, firstCharacter: .minus)
        let result15 = Parser.parse(data15, firstCharacter: .dot)

        XCTAssertEqual(result1, .withSuccess(result: .integer(-123), messages: []))
        XCTAssertEqual(result2, .withSuccess(result: .integer(3), messages: []))
        XCTAssertEqual(result3, .withSuccess(result: .double(10.01), messages: []))
        XCTAssertEqual(result4, .withSuccess(result: .double(10), messages: []))
        XCTAssertEqual(result5, .withSuccess(result: .integer(1), messages: []))
        XCTAssertEqual(result6, .withSuccess(result: .integer(100), messages: []))
        XCTAssertEqual(result7, .withSuccess(result: .double(-10.2), messages: []))
        XCTAssertEqual(result8, .withSuccess(result: .integer(10), messages: []))
        XCTAssertEqual(result9, .withErrors(messages: [
            Problem.unexpectedSymbol("e").reference(line: 1, col: 3, level: .error),
        ]))
        XCTAssertEqual(result10, .withErrors(messages: [
            Problem.unexpectedSymbol("n").reference(line: 1, col: 3, level: .error),
        ]))
        XCTAssertEqual(result11, .withSuccess(result: .double(-964), messages: []))
        XCTAssertEqual(result12, .withSuccess(result: .integer(18), messages: []))
        XCTAssertEqual(result13, .withErrors(messages: [
            Problem.endOfStream.reference(line: 1, col: 2, level: .error),
        ]))
        XCTAssertEqual(result14, .withSuccess(result: .double(-0.1), messages: []))
        XCTAssertEqual(result15, .withSuccess(result: .double(0.2), messages: []))

        XCTAssertEqual(data12.currentCol, 3)
        XCTAssertEqual(data12.currentCharacter, " ")
    }

    func testBoolParser() throws {
        typealias Parser = KVBlock.Parser.ValueParser.BoolParser
        typealias Problem = KVBlock.Parser.ValueParser.BoolParser.Problem

        let data1 = DataSource("true")
        let data2 = DataSource("false // true")
        let data3 = DataSource("tRuE\n")
        let data4 = DataSource("FALSE/")
        let data5 = DataSource("tru ")
        let data6 = DataSource("false- ")
        let data7 = DataSource("faL")

        let result1 = Parser.parse(data1, firstCharacter: .t)
        let result2 = Parser.parse(data2, firstCharacter: .f)
        let result3 = Parser.parse(data3, firstCharacter: .t)
        let result4 = Parser.parse(data4, firstCharacter: .f)
        let result5 = Parser.parse(data5, firstCharacter: .t)
        let result6 = Parser.parse(data6, firstCharacter: .f)
        let result7 = Parser.parse(data7, firstCharacter: .f)

        XCTAssertEqual(result1, .withSuccess(result: true, messages: []))
        XCTAssertEqual(result2, .withSuccess(result: false, messages: []))
        XCTAssertEqual(result3, .withSuccess(result: true, messages: []))
        XCTAssertEqual(result4, .withSuccess(result: false, messages: []))
        XCTAssertEqual(result5, .withErrors(messages: [
            Problem.unexpectedSymbol(" ").reference(line: 1, col: 4, level: .error),
        ]))
        XCTAssertEqual(result6, .withErrors(messages: [
            Problem.unexpectedSymbol("-").reference(line: 1, col: 6, level: .error),
        ]))
        XCTAssertEqual(result7, .withErrors(messages: [
            Problem.endOfStream.reference(line: 1, col: 4, level: .error),
        ]))

        XCTAssertEqual(data2.currentCol, 6)
        XCTAssertEqual(data2.currentCharacter, " ")
    }

    func testEnvParser() throws {
        typealias Parser = KVBlock.Parser.ValueParser.EnvParser
        typealias Problem = KVBlock.Parser.ValueParser.EnvParser.Problem

        let data1 = DataSource("env(  \"yes?\" ) ")
        let data2 = DataSource("env(\"no 12\") // is this a comment? \n")
        let data3 = DataSource("env( \"\\\"\")// no?")
        let data4 = DataSource("env(\"\")\n")
        let data5 = DataSource("enve(\"1\") ")
        let data6 = DataSource("env(\"--\")- ")
        let data7 = DataSource("env( \"18\u{1b} \u{1b}a\n\")")
        let data8 = DataSource("env(\"E\")}")
        let data9 = DataSource("env(\"E\")")

        let result1 = Parser.parse(data1)
        let result2 = Parser.parse(data2)
        let result3 = Parser.parse(data3)
        let result4 = Parser.parse(data4)
        let result5 = Parser.parse(data5)
        let result6 = Parser.parse(data6)
        let result7 = Parser.parse(data7)
        let result8 = Parser.parse(data8)
        let result9 = Parser.parse(data9)

        XCTAssertEqual(result1, .withSuccess(result: "yes?", messages: []))
        XCTAssertEqual(result2, .withSuccess(result: "no 12", messages: []))
        XCTAssertEqual(result3, .withSuccess(result: "\"", messages: []))
        XCTAssertEqual(result4, .withSuccess(result: "", messages: []))
        XCTAssertEqual(result5, .withErrors(messages: [
            Problem.unexpectedSymbol("e").reference(line: 1, col: 4, level: .error),
        ]))
        XCTAssertEqual(result6, .withErrors(messages: [
            Problem.unexpectedSymbol("-").reference(line: 1, col: 10, level: .error),
        ]))
        XCTAssertEqual(result7, .withErrors(messages: [
            KVBlock.Parser.ValueParser.QuotedStringParser.Problem.controlCharacter.reference(line: 1, col: 6, level: .warning),
            KVBlock.Parser.ValueParser.QuotedStringParser.Problem.newLine.reference(line: 1, col: 13, level: .error),
            Problem.unexpectedSymbol("\n").reference(line: 1, col: 13, level: .error),
        ]))

        XCTAssertEqual(result8, .withSuccess(result: "E", messages: []))
        XCTAssertEqual(result9, .withErrors(messages: [
            Problem.endOfStream.reference(line: 1, col: 9, level: .error),
        ]))

        XCTAssertEqual(data2.currentCol, 13)
        XCTAssertEqual(data2.currentCharacter, " ")

        XCTAssertEqual(data8.currentCol, 9)
    }

    func testValueParser() throws {
        typealias Parser = KVBlock.Parser.ValueParser
        typealias Problem = KVBlock.Parser.ValueParser.Problem

        let data1 = DataSource("= \"hello world\" // this is something else")
        data1.skipWhiteSpaces()
        let data2 = DataSource("-123.34/")
        let data3 = DataSource("false")
        let data4 = DataSource("env(  \"  8\u{1b} 8\u{1b}\")\n")
        let data5 = DataSource("")
        let data6 = DataSource("fals")
        let data7 = DataSource(" \n-18b ")
        data7.skipLine()
        let data8 = DataSource("// 23")
        let data9 = DataSource("env(\"O\")}")

        let result1 = Parser.parse(data1)
        let result2 = Parser.parse(data2)
        let result3 = Parser.parse(data3)
        let result4 = Parser.parse(data4)
        let result5 = Parser.parse(data5)
        let result6 = Parser.parse(data6)
        let result7 = Parser.parse(data7)
        let result8 = Parser.parse(data8)
        let result9 = Parser.parse(data9)

        XCTAssertEqual(result1, .withSuccess(result: .string("hello world"), messages: []))
        XCTAssertEqual(result2, .withSuccess(result: .number(-123.34), messages: []))
        XCTAssertEqual(result3, .withSuccess(result: .boolean(false), messages: []))
        XCTAssertEqual(result4, .withSuccess(result: .env("  8 8"), messages: [
            KVBlock.Parser.ValueParser.QuotedStringParser.Problem.controlCharacter.reference(line: 1, col: 7, level: .warning),
        ]))
        XCTAssertEqual(result5, .withErrors(messages: [
            Problem.endOfStream.reference(line: 1, col: 1, level: .error),
        ]))
        XCTAssertEqual(result6, .withErrors(messages: [
            KVBlock.Parser.ValueParser.BoolParser.Problem.endOfStream.reference(line: 1, col: 5, level: .error),
        ]))
        XCTAssertEqual(result7, .withErrors(messages: [
            KVBlock.Parser.ValueParser.NumberParser.Problem.unexpectedSymbol("b").reference(line: 2, col: 4, level: .error),
        ]))
        XCTAssertEqual(result8, .withErrors(messages: [
            Problem.unexpectedSymbol("/").reference(line: 1, col: 1, level: .error),
        ]))
        XCTAssertEqual(result9, .withSuccess(result: .env("O"), messages: []))
    }
}
