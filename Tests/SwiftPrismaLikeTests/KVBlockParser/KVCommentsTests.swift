@testable import Core
import XCTest

final class KVCommentsTests: XCTestCase {
    func testCommentsParser() throws {
        let parser = KVBlockParser.CommentsParser()

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

        let result1 = parser.parse(data1)
        let result2 = parser.parse(data2)
        let result3 = parser.parse(data3)
        let result4 = parser.parse(data4)
        let result5 = parser.parse(data5)
        let result6 = parser.parse(data6)
        let result7 = parser.parse(data7)
        let result8 = parser.parse(data8)
        let result9 = parser.parse(data9)
        let result10 = parser.parse(data10)

        XCTAssertEqual(result1, .withSuccess(result: nil, warnings: []))
        XCTAssertEqual(data1.currentLine, 1)
        XCTAssertEqual(data1.currentCol, 3)

        XCTAssertEqual(result2, .withSuccess(result: nil, warnings: []))
        XCTAssertEqual(data2.currentLine, 2)
        XCTAssertEqual(data2.currentCol, 1)

        XCTAssertEqual(result3, .withSuccess(result: "", warnings: []))
        XCTAssertEqual(data3.currentLine, 1)
        XCTAssertEqual(data3.currentCol, 4)

        XCTAssertEqual(result4, .withSuccess(result: "hello world k=1", warnings: []))
        XCTAssertEqual(data4.currentLine, 2)
        XCTAssertEqual(data4.currentCol, 1)

        XCTAssertEqual(result5, .withSuccess(result: nil, warnings: []))
        XCTAssertEqual(data5.currentLine, 1)
        XCTAssertEqual(data5.currentCol, 4)

        XCTAssertEqual(result6, .withSuccess(result: "1", warnings: []))
        XCTAssertEqual(data6.currentLine, 1)
        XCTAssertEqual(data6.currentCol, 5)

        XCTAssertEqual(result7, .withErrors(warnings: [], errors: [
            .init(message: "Unexpected symbol encoutnered while parsing a comment opening", line: 1, col: 2),
        ]))
        XCTAssertEqual(data7.currentLine, 1)
        XCTAssertEqual(data7.currentCol, 2)

        XCTAssertEqual(result8, .withErrors(warnings: [], errors: [
            .init(message: "Unexpected symbol encoutnered while parsing a comment opening", line: 1, col: 2),
        ]))
        XCTAssertEqual(data8.currentLine, 1)
        XCTAssertEqual(data8.currentCol, 2)

        XCTAssertEqual(result9, .withSuccess(result: "This is a new comment", warnings: []))
        XCTAssertEqual(data9.currentLine, 1)
        XCTAssertEqual(data9.currentCol, 34)

        XCTAssertEqual(result10, .withSuccess(result: "hello", warnings: []))
        XCTAssertEqual(data10.currentLine, 2)
        XCTAssertEqual(data10.currentCol, 1)
    }
}
