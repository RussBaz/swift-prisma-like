@testable import Core
import XCTest

final class KVLineTests: XCTestCase {
    func testKVLineParser() throws {
        let parser = KVBlockParser.KeyValueParser()

        let data1 = DataSource("hello_world = -18 //  Whatever test\n12")
        let data2 = DataSource("   this= \"nothing special, ok?\"///Poor boys   \n")
        let c2 = data2.skipWhiteSpaces()
        let data3 = DataSource("l=env(\"E\")}\n")
        let data4 = DataSource("w=env(\"w\")")
        let data5 = DataSource("w=\"w\" } hello")
        let data6 = DataSource("w=\"w\" c}")
        let data7 = DataSource("w=\"w\"}bad")
        let data8 = DataSource("ab =  \"1\u{1b}\"}")

        let result1 = parser.parse(data1, firstCharacter: "h")
        let result2 = parser.parse(data2, firstCharacter: "t")
        let result3 = parser.parse(data3, firstCharacter: "l")
        let result4 = parser.parse(data4, firstCharacter: "w")
        let result5 = parser.parse(data5, firstCharacter: "w")
        let result6 = parser.parse(data6, firstCharacter: "w")
        let result7 = parser.parse(data7, firstCharacter: "w")
        let result8 = parser.parse(data8, firstCharacter: "a")

        XCTAssertEqual(result1, .withSuccess(result: .newLine(.init(key: "hello_world", value: .integer(-18))), warnings: []))
        XCTAssertEqual(data1.currentLine, 2)
        XCTAssertEqual(data1.currentCol, 1)

        XCTAssertEqual(result2, .withSuccess(result: .newLine(.init(key: "this", value: .string("nothing special, ok?"), comments: ["Poor boys"])), warnings: []))
        XCTAssertEqual(c2, "t")
        XCTAssertEqual(data2.currentLine, 2)
        XCTAssertEqual(data2.currentCol, 1)

        XCTAssertEqual(result3, .withSuccess(result: .endOfBlock(.init(key: "l", value: .env("E"))), warnings: []))
        XCTAssertEqual(data3.currentLine, 2)
        XCTAssertEqual(data3.currentCol, 1)

        XCTAssertEqual(result4, .withErrors(warnings: [], errors: [
            .init(message: "Unexpected end of stream encountered while parsing a KV line", line: 1, col: 11),
        ]))

        XCTAssertEqual(result5, .withSuccess(result: .endOfBlock(.init(key: "w", value: .string("w"))), warnings: [
            .init(message: "Unexpected symbols encountered and skipped after parsing a KV line", line: 1, col: 9),
        ]))

        XCTAssertEqual(result6, .withErrors(warnings: [], errors: [
            .init(message: "Unexpected symbol encoutnered while parsing a KV line", line: 1, col: 7),
        ]))

        XCTAssertEqual(result7, .withErrors(warnings: [], errors: [
            .init(message: "Unexpected symbol encoutnered while parsing a KV line", line: 1, col: 7),
        ]))

        XCTAssertEqual(result8, .withSuccess(result: .endOfBlock(.init(key: "ab", value: .string("1"))), warnings: [
            .init(message: "Control characters were detected and skipped in the quoted string", line: 1, col: 7),
        ]))
    }
}
