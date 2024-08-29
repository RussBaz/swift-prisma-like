@testable import Core
import XCTest

final class KVBlockTests: XCTestCase {
    func testAllValid() throws {
        try XCTSkipIf(true)

        let blockName = "block"
        let comments = ["hello", "world"]
        let block = """
        a  ="string?"  //this is nice
        /// What is it?
          b=       -1       ///    A thing?

        //  oOsps?
        c = true

        d     =       env("ooops")

           /// Well . . . }
        e = false
        f=-10.023
         // yes
        g = env(foo(bar(+3))) // this line will be ignored
        }
        """

        let expectedResult: KVBlock = .init(
            name: blockName,
            lines: [
                .init(key: "a", value: .string("string?"), comments: []),
                .init(key: "b", value: .integer(-1), comments: [
                    "What is it?",
                    "A thing?",
                ]),
                .init(key: "c", value: .boolean(true), comments: []),
                .init(key: "d", value: .env("ooops"), comments: []),
                .init(key: "e", value: .boolean(false), comments: ["Well . . . }"]),
                .init(key: "f", value: .number(-10.023), comments: []),
                // "g" key will be ignored as we do not expect other functions in KV blocks (only 'env' is expected)
            ],
            comments: comments
        )

        var parser = KVBlockParser(name: blockName, comments: comments)
        let data = DataSource(block)

        let result = parser.parse(data)

        XCTAssertEqual(.withSuccess(result: expectedResult, warnings: []), result)
    }

    func testIndividualLineParser() throws {
        var parser = KVBlockParser(name: "block", comments: [])

        let data1 = DataSource("d     =       env(\"ooops\")\n")
        let data2 = DataSource("\n")
        let data3 = DataSource("}    \n")
        let data4 = DataSource("   // Hello\n")
        let data5 = DataSource("   /// world!\n")
        let data6 = DataSource("key= -12// Nothing else } \n")
        let data7 = DataSource("a=\"b\u{1b}\" ///  no-comment }  \n")
        let data8 = DataSource("  c = true }")
        let data9 = DataSource(" ")

        let result1 = parser.parseLine(data1)
        parser.resetState()
        let result2 = parser.parseLine(data2)
        parser.resetState()
        let result3 = parser.parseLine(data3)
        parser.resetState()
        let result4 = parser.parseLine(data4)
        parser.resetState()
        let result5 = parser.parseLine(data5)
        parser.resetState()
        let result6 = parser.parseLine(data6)
        parser.resetState()
        let result7 = parser.parseLine(data7)
        parser.resetState()
        let result8 = parser.parseLine(data8)
        parser.resetState()
        let result9 = parser.parseLine(data9)

        XCTAssertEqual(result1, .withSuccess(result: .newLine(.kv(.init(key: "d", value: .env("ooops")))), warnings: []))
        XCTAssertEqual(data1.currentLine, 2)
        XCTAssertEqual(data1.currentCol, 1)
        XCTAssertEqual(result2, .withSuccess(result: .newLine(.empty), warnings: []))
        XCTAssertEqual(result3, .withSuccess(result: .endOfBlock(.empty), warnings: []))
        XCTAssertEqual(result4, .withSuccess(result: .newLine(.empty), warnings: []))
        XCTAssertEqual(result5, .withSuccess(result: .newLine(.comment("world!")), warnings: []))
        XCTAssertEqual(result6, .withSuccess(result: .newLine(.kv(.init(key: "key", value: .integer(-12)))), warnings: []))
        XCTAssertEqual(result7, .withSuccess(result: .newLine(.kv(.init(key: "a", value: .string("b"), comments: ["no-comment }"]))), warnings: [
            .init(message: "Control characters were detected and skipped in the quoted string", line: 1, col: 3),
        ]))
        XCTAssertEqual(result8, .withSuccess(result: .endOfBlock(.kv(.init(key: "c", value: .boolean(true)))), warnings: []))
        XCTAssertEqual(result9, .withErrors(warnings: [], errors: [
            .init(message: "Unexpected end of stream encountered while parsing a KV block line", line: 1, col: 2)
        ]))
    }
}
