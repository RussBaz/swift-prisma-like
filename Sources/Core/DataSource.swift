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

    private(set) var currentPos: String.Index
    private(set) var currentCol = 1
    private(set) var currentLine = 1

    init(_ data: String) {
        self.data = data
        currentPos = data.startIndex
    }

    init?(file name: String) {
        guard let s = try? String(contentsOfFile: name) else { return nil }
        data = s
        currentPos = s.startIndex
    }

    func nextCharacter() -> Character? {
        guard !endReached else { return nil }
        currentPos = data.index(after: currentPos)

        guard let c = currentCharacter else { return nil }

        if c.isNewline {
            currentCol = 1
            currentLine += 1
        } else {
            currentCol += 1
        }

        return c
    }

    @discardableResult
    func nextPos() -> Bool {
        guard !endReached else { return false }
        currentPos = data.index(after: currentPos)

        guard let c = currentCharacter else { return false }

        if c.isNewline {
            currentCol = 1
            currentLine += 1
        } else {
            currentCol += 1
        }

        return true
    }

    func skipWhiteSpaces() {
        guard let c = currentCharacter, c == " " else { return }
        while let c = nextCharacter() {
            guard c == " " else { return }
        }
    }

    func skipLine() {
        guard let c = currentCharacter, !c.isNewline else { return }
        while let c = nextCharacter() {
            guard !c.isNewline else { return }
        }
    }

    var endReached: Bool {
        currentPos == data.endIndex
    }

    var atBeginning: Bool {
        currentPos == data.startIndex
    }

    var currentCharacter: Character? {
        guard !endReached else { return nil }

        return data[currentPos]
    }

    var curentPosition: FixedPosition {
        get {
            .init(pos: currentPos, col: currentCol, line: currentLine)
        }
        set {
            currentPos = newValue.pos
            currentCol = newValue.col
            currentLine = newValue.line
        }
    }
}
