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

        let data = DataSource(block)

        let result = KVBlock.Parser.parse(data, name: blockName, comments: comments)

        XCTAssertEqual(.withSuccess(result: expectedResult, messages: []), result)
    }

    func testIndividualLineParser() throws {
        let data1 = DataSource("d     =       env(\"ooops\")\n")
        let data2 = DataSource("\n")
        let data3 = DataSource("}    \n")
        let data4 = DataSource("   // Hello\n")
        let data5 = DataSource("   /// world!\n")
        let data6 = DataSource("key= -12// Nothing else } \n")
        let data7 = DataSource("a=\"b\u{1b}\" ///  no-comment }  \n")
        let data8 = DataSource("  c = true }")
        let data9 = DataSource(" ")

        let result1 = KVBlock.Parser.parseLine(data1)
        let result2 = KVBlock.Parser.parseLine(data2)
        let result3 = KVBlock.Parser.parseLine(data3)
        let result4 = KVBlock.Parser.parseLine(data4)
        let result5 = KVBlock.Parser.parseLine(data5)
        let result6 = KVBlock.Parser.parseLine(data6)
        let result7 = KVBlock.Parser.parseLine(data7)
        let result8 = KVBlock.Parser.parseLine(data8)
        let result9 = KVBlock.Parser.parseLine(data9)

        XCTAssertEqual(result1, .withSuccess(result: .newLine(.kv(.init(key: "d", value: .env("ooops")))), messages: []))
        XCTAssertEqual(data1.currentLine, 2)
        XCTAssertEqual(data1.currentCol, 1)
        XCTAssertEqual(result2, .withSuccess(result: .newLine(.empty), messages: []))
        XCTAssertEqual(result3, .withSuccess(result: .endOfBlock(.empty), messages: []))
        XCTAssertEqual(result4, .withSuccess(result: .newLine(.empty), messages: []))
        XCTAssertEqual(result5, .withSuccess(result: .newLine(.comment("world!")), messages: []))
        XCTAssertEqual(result6, .withSuccess(result: .newLine(.kv(.init(key: "key", value: .integer(-12)))), messages: []))
        XCTAssertEqual(result7, .withSuccess(result: .newLine(.kv(.init(key: "a", value: .string("b"), comments: ["no-comment }"]))), messages: [
            KVBlock.Parser.ValueParser.QuotedStringParser.Problem.controlCharacter.reference(line: 1, col: 3, level: .warning),
        ]))
        XCTAssertEqual(result8, .withSuccess(result: .endOfBlock(.kv(.init(key: "c", value: .boolean(true)))), messages: []))
        XCTAssertEqual(result9, .withErrors(messages: [
            KVBlock.Parser.Problem.endOfStream.reference(line: 1, col: 2, level: .error),
        ]))
    }
}
