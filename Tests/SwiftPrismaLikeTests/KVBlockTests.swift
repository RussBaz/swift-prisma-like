@testable import Core
import XCTest

final class KVBlockTests: XCTestCase {
    func testBasicExample() throws {
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

        guard let result = parser.parse(data) else {
            return XCTFail("The block was not parsed")
        }

        XCTAssertEqual(result, expectedResult)
    }
}
