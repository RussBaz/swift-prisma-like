@testable import Core
import XCTest

final class KVCommentsTests: XCTestCase {
    func testCommentsParser() throws {
        typealias Parser = KVBlock.Parser.CommentsParser
        typealias Problem = KVBlock.Parser.CommentsParser.Problem

        let data1 = DataSource("//")
        let data2 = DataSource("// hello world k=1\n k=2")
        let data3 = DataSource("///")
        let data4 = DataSource("/// hello world k=1\n k=2")
        let data5 = DataSource("//1")
        let data6 = DataSource("///1")
        let data7 = DataSource("/ 2\n 3")
        let data8 = DataSource("/error")
        let data9 = DataSource("   ///  This is a new comment    ")
        data9.skipWhiteSpaces()
        let data10 = DataSource("/// hello\n")

        let result1 = Parser.parse(data1)
        let result2 = Parser.parse(data2)
        let result3 = Parser.parse(data3)
        let result4 = Parser.parse(data4)
        let result5 = Parser.parse(data5)
        let result6 = Parser.parse(data6)
        let result7 = Parser.parse(data7)
        let result8 = Parser.parse(data8)
        let result9 = Parser.parse(data9)
        let result10 = Parser.parse(data10)

        XCTAssertEqual(result1, .withSuccess(result: nil, messages: []))
        XCTAssertEqual(data1.currentLine, 1)
        XCTAssertEqual(data1.currentCol, 3)

        XCTAssertEqual(result2, .withSuccess(result: nil, messages: []))
        XCTAssertEqual(data2.currentLine, 2)
        XCTAssertEqual(data2.currentCol, 1)

        XCTAssertEqual(result3, .withSuccess(result: "", messages: []))
        XCTAssertEqual(data3.currentLine, 1)
        XCTAssertEqual(data3.currentCol, 4)

        XCTAssertEqual(result4, .withSuccess(result: "hello world k=1", messages: []))
        XCTAssertEqual(data4.currentLine, 2)
        XCTAssertEqual(data4.currentCol, 1)

        XCTAssertEqual(result5, .withSuccess(result: nil, messages: []))
        XCTAssertEqual(data5.currentLine, 1)
        XCTAssertEqual(data5.currentCol, 4)

        XCTAssertEqual(result6, .withSuccess(result: "1", messages: []))
        XCTAssertEqual(data6.currentLine, 1)
        XCTAssertEqual(data6.currentCol, 5)

        XCTAssertEqual(result7, .withErrors(messages: [
            Problem.unexpectedSymbol(" ").reference(line: 1, col: 2, level: .error),
        ]))
        XCTAssertEqual(data7.currentLine, 1)
        XCTAssertEqual(data7.currentCol, 2)

        XCTAssertEqual(result8, .withErrors(messages: [
            Problem.unexpectedSymbol("e").reference(line: 1, col: 2, level: .error),
        ]))
        XCTAssertEqual(data8.currentLine, 1)
        XCTAssertEqual(data8.currentCol, 2)

        XCTAssertEqual(result9, .withSuccess(result: "This is a new comment", messages: []))
        XCTAssertEqual(data9.currentLine, 1)
        XCTAssertEqual(data9.currentCol, 34)

        XCTAssertEqual(result10, .withSuccess(result: "hello", messages: []))
        XCTAssertEqual(data10.currentLine, 2)
        XCTAssertEqual(data10.currentCol, 1)
    }
}
