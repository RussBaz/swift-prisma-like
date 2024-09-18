@testable import Core
import XCTest

final class KVKeyTests: XCTestCase {
    func testKeyParser() throws {
        typealias Parser = KVBlock.Parser.KeyParser
        typealias Problem = KVBlock.Parser.KeyParser.Problem

        let data1 = DataSource("this_is_a_key    = ")
        let data2 = DataSource(" k=123 \n")
        data2.nextPos()
        let data3 = DataSource("hello-world =")
        let data4 = DataSource("hello\nworld=")
        let data5 = DataSource("hello")
        let data6 = DataSource("hello world")

        let result1 = Parser.parse(data1, firstCharacter: "t")
        let result2 = Parser.parse(data2, firstCharacter: "k")
        let result3 = Parser.parse(data3, firstCharacter: "h")
        let result4 = Parser.parse(data4, firstCharacter: "h")
        let result5 = Parser.parse(data5, firstCharacter: "h")
        let result6 = Parser.parse(data6, firstCharacter: "h")

        XCTAssertEqual(result1, .withSuccess(result: "this_is_a_key", messages: []))
        XCTAssertEqual(data1.currentLine, 1)
        XCTAssertEqual(data1.currentCol, 19)

        XCTAssertEqual(result2, .withSuccess(result: "k", messages: []))
        XCTAssertEqual(data2.currentLine, 1)
        XCTAssertEqual(data2.currentCol, 4)

        XCTAssertEqual(result3, .withErrors(messages: [
            Problem.unexpectedSymbol("-").reference(line: 1, col: 6, level: .error),
        ]))
        XCTAssertEqual(data3.currentLine, 1)
        XCTAssertEqual(data3.currentCol, 6)

        XCTAssertEqual(result4, .withErrors(messages: [
            Problem.endOfLine.reference(line: 1, col: 6, level: .error),
        ]))
        XCTAssertEqual(data4.currentLine, 1)
        XCTAssertEqual(data4.currentCol, 6)

        XCTAssertEqual(result5, .withErrors(messages: [
            Problem.endOfStream.reference(line: 1, col: 6, level: .error),
        ]))
        XCTAssertEqual(data5.currentLine, 1)
        XCTAssertEqual(data5.currentCol, 6)

        XCTAssertEqual(result6, .withErrors(messages: [
            Problem.missingEqualsSign("w").reference(line: 1, col: 7, level: .error),
        ]))
        XCTAssertEqual(data6.currentLine, 1)
        XCTAssertEqual(data6.currentCol, 7)
    }
}
