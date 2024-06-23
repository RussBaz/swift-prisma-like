@testable import Core
import XCTest

final class DataSourceTests: XCTestCase {
    func testBasicIterating() throws {
        let data = DataSource("h \nw\n\n 1 ")

        XCTAssertEqual(data.currentCharacter, "h")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 1)
        XCTAssertTrue(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, " ")
        XCTAssertEqual(data.currentCol, 2)
        XCTAssertEqual(data.currentLine, 1)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        let oldLocation = data.curentPosition

        XCTAssertEqual(data.data.distance(from: data.data.startIndex, to: oldLocation.pos) as Int, 1)
        XCTAssertEqual(oldLocation.col, 2)
        XCTAssertEqual(oldLocation.line, 1)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 3)
        XCTAssertEqual(data.currentLine, 1)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertNotEqual(data.curentPosition, oldLocation)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, "w")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 2)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 2)
        XCTAssertEqual(data.currentLine, 2)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 3)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, " ")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 4)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, "1")
        XCTAssertEqual(data.currentCol, 2)
        XCTAssertEqual(data.currentLine, 4)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertTrue(data.nextPos())
        XCTAssertEqual(data.currentCharacter, " ")
        XCTAssertEqual(data.currentCol, 3)
        XCTAssertEqual(data.currentLine, 4)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertFalse(data.nextPos())
        XCTAssertEqual(data.currentCharacter, nil)
        XCTAssertEqual(data.currentCol, 4)
        XCTAssertEqual(data.currentLine, 4)
        XCTAssertFalse(data.atBeginning)
        XCTAssertTrue(data.endReached)

        XCTAssertFalse(data.nextPos())
        XCTAssertEqual(data.currentCharacter, nil)
        XCTAssertEqual(data.currentCol, 4)
        XCTAssertEqual(data.currentLine, 4)
        XCTAssertFalse(data.atBeginning)
        XCTAssertTrue(data.endReached)

        XCTAssertFalse(data.nextPos())
        XCTAssertEqual(data.currentCharacter, nil)
        XCTAssertEqual(data.currentCol, 4)
        XCTAssertEqual(data.currentLine, 4)
        XCTAssertFalse(data.atBeginning)
        XCTAssertTrue(data.endReached)

        XCTAssertNotEqual(data.curentPosition, oldLocation)
        data.curentPosition = oldLocation
        XCTAssertEqual(data.curentPosition, oldLocation)
        XCTAssertEqual(data.currentCharacter, " ")
        XCTAssertEqual(data.currentCol, 2)
        XCTAssertEqual(data.currentLine, 1)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        XCTAssertEqual(data.nextCharacter(), "\n")
        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 3)
        XCTAssertEqual(data.currentLine, 1)
        XCTAssertFalse(data.atBeginning)
        XCTAssertFalse(data.endReached)

        let data2 = DataSource("\n123\n")
        let oldLocation2 = data2.curentPosition

        XCTAssertEqual(data2.currentCharacter, "\n")
        XCTAssertEqual(data2.currentCol, 1)
        XCTAssertEqual(data2.currentLine, 1)
        XCTAssertTrue(data2.atBeginning)
        XCTAssertFalse(data2.endReached)

        data2.nextPos()

        XCTAssertEqual(data2.currentCharacter, "1")
        XCTAssertEqual(data2.currentCol, 2)
        XCTAssertEqual(data2.currentLine, 1)
        XCTAssertFalse(data2.atBeginning)
        XCTAssertFalse(data2.endReached)

        data2.nextPos()
        data2.nextPos()
        data2.nextPos()
        data2.nextPos()
        data2.nextPos()

        XCTAssertNil(data2.currentCharacter)
        XCTAssertEqual(data2.currentCol, 1)
        XCTAssertEqual(data2.currentLine, 2)
        XCTAssertFalse(data2.atBeginning)
        XCTAssertTrue(data2.endReached)

        data2.curentPosition = oldLocation2

        XCTAssertEqual(data2.currentCharacter, "\n")
        XCTAssertEqual(data2.currentCol, 1)
        XCTAssertEqual(data2.currentLine, 1)
        XCTAssertTrue(data2.atBeginning)
        XCTAssertFalse(data2.endReached)
    }

    func testSkippingWhiteSpaces() throws {
        let data = DataSource("h  1\n 2 \na  \n")

        data.skipWhiteSpaces()

        XCTAssertEqual(data.currentCharacter, "1")
        XCTAssertEqual(data.currentCol, 4)
        XCTAssertEqual(data.currentLine, 1)

        data.nextPos()
        data.nextPos()
        data.skipWhiteSpaces()

        XCTAssertEqual(data.currentCharacter, "2")
        XCTAssertEqual(data.currentCol, 2)
        XCTAssertEqual(data.currentLine, 2)

        data.nextPos()
        data.skipWhiteSpaces()

        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 4)
        XCTAssertEqual(data.currentLine, 2)

        data.skipWhiteSpaces()

        XCTAssertEqual(data.currentCharacter, "a")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 3)

        data.nextPos()
        data.skipWhiteSpaces()

        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 4)
        XCTAssertEqual(data.currentLine, 3)

        data.skipWhiteSpaces()

        XCTAssertNil(data.currentCharacter)
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 4)

        data.skipWhiteSpaces()

        XCTAssertNil(data.currentCharacter)
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 4)

        data.skipWhiteSpaces()

        XCTAssertNil(data.currentCharacter)
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 4)
    }

    func testSkipLines() throws {
        let data = DataSource("hello\n \n\n\n")

        data.nextPos()
        data.skipLine()

        XCTAssertEqual(data.currentCharacter, " ")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 2)

        data.skipLine()

        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 3)

        data.nextPos()

        XCTAssertEqual(data.currentCharacter, "\n")
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 4)

        data.skipLine()

        XCTAssertNil(data.currentCharacter)
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 5)

        data.skipLine()

        XCTAssertNil(data.currentCharacter)
        XCTAssertEqual(data.currentCol, 1)
        XCTAssertEqual(data.currentLine, 5)
    }
}
