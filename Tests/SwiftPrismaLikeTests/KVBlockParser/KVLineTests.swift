@testable import Core
import XCTest

final class KVLineTests: XCTestCase {
    func testKVLineParser() throws {
        typealias Parser = KVBlock.Parser.KeyValueParser
        typealias Problem = KVBlock.Parser.KeyValueParser.Problem

        let data1 = DataSource("hello_world = -18 //  Whatever test\n12")
        let data2 = DataSource("   this= \"nothing special, ok?\"///Poor boys   \n")
        let c2 = data2.skipWhiteSpaces()
        let data3 = DataSource("l=env(\"E\")}\n")
        let data4 = DataSource("w=env(\"w\")")
        let data5 = DataSource("w=\"w\" } hello")
        let data6 = DataSource("w=\"w\" c}")
        let data7 = DataSource("w=\"w\"}bad")
        let data8 = DataSource("ab =  \"1\u{1b}\"}")

        let result1 = Parser.parse(data1, firstCharacter: "h")
        let result2 = Parser.parse(data2, firstCharacter: "t")
        let result3 = Parser.parse(data3, firstCharacter: "l")
        let result4 = Parser.parse(data4, firstCharacter: "w")
        let result5 = Parser.parse(data5, firstCharacter: "w")
        let result6 = Parser.parse(data6, firstCharacter: "w")
        let result7 = Parser.parse(data7, firstCharacter: "w")
        let result8 = Parser.parse(data8, firstCharacter: "a")

        XCTAssertEqual(result1, .withSuccess(result: .newLine(.init(key: "hello_world", value: .integer(-18))), messages: []))
        XCTAssertEqual(data1.currentLine, 2)
        XCTAssertEqual(data1.currentCol, 1)

        XCTAssertEqual(result2, .withSuccess(result: .newLine(.init(key: "this", value: .string("nothing special, ok?"), comments: ["Poor boys"])), messages: []))
        XCTAssertEqual(c2, "t")
        XCTAssertEqual(data2.currentLine, 2)
        XCTAssertEqual(data2.currentCol, 1)

        XCTAssertEqual(result3, .withSuccess(result: .endOfBlock(.init(key: "l", value: .env("E"))), messages: []))
        XCTAssertEqual(data3.currentLine, 2)
        XCTAssertEqual(data3.currentCol, 1)

        XCTAssertEqual(result4, .withErrors(messages: [
            KVBlock.Parser.ValueParser.EnvParser.Problem.endOfStream.reference(line: 1, col: 11, level: .error),
        ]))

        XCTAssertEqual(result5, .withSuccess(result: .endOfBlock(.init(key: "w", value: .string("w"))), messages: [
            Problem.skippedSymbols.reference(line: 1, col: 9, level: .warning),
        ]))

        XCTAssertEqual(result6, .withErrors(messages: [
            Problem.unexpectedSymbol("c").reference(line: 1, col: 7, level: .error),
        ]))

        XCTAssertEqual(result7, .withErrors(messages: [
            Problem.unexpectedSymbol("b").reference(line: 1, col: 7, level: .error),
        ]))

        XCTAssertEqual(result8, .withSuccess(result: .endOfBlock(.init(key: "ab", value: .string("1"))), messages: [
            KVBlock.Parser.ValueParser.QuotedStringParser.Problem.controlCharacter.reference(line: 1, col: 7, level: .warning),
        ]))
    }
}
