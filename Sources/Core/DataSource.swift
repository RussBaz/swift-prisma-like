final class DataSource {
    struct FixedPosition {
        let pos: String.Index
        let col: Int
        let line: Int

        fileprivate init(pos: String.Index, col: Int, line: Int) {
            self.pos = pos
            self.col = col
            self.line = line
        }
    }

    let data: String

    private(set) var nextPos: String.Index
    private(set) var currentCol = 1
    private(set) var currentLine = 1

    init(_ data: String) {
        self.data = data
        nextPos = data.startIndex
    }

    init?(file name: String) {
        guard let s = try? String(contentsOfFile: name) else { return nil }
        data = s
        nextPos = s.startIndex
    }

    func nextCharacter() -> Character? {
        guard !endReached else { return nil }

        let c = data[nextPos]

        if c.isNewline {
            currentCol = 1
            currentLine += 1
        } else {
            currentCol += 1
        }

        // Only move the index pointer at the end of operation
        nextPos = data.index(after: nextPos)

        return c
    }

    var endReached: Bool {
        nextPos == data.endIndex
    }

    var curentPosition: FixedPosition {
        get {
            .init(pos: nextPos, col: currentCol, line: currentLine)
        }
        set {
            nextPos = newValue.pos
            currentCol = newValue.col
            currentLine = newValue.line
        }
    }
}
