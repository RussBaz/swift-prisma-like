final class DataSource {
    struct FixedPosition: Equatable {
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

    private var newLineEncountered = false

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

        if newLineEncountered {
            newLineEncountered = false
            currentCol = 1
            currentLine += 1
        } else {
            currentCol += 1
        }

        guard let c = currentCharacter else { return nil }

        if c.isNewline {
            newLineEncountered = true
        }

        return c
    }

    @discardableResult
    func nextPos() -> Bool {
        guard let _ = nextCharacter() else { return false }

        return true
    }

    func skipWhiteSpaces() {
        while let c = nextCharacter() {
            guard c == " " else { return }
        }
    }

    func skipLine() {
        guard let c = currentCharacter else { return }
        guard !c.isNewline else {
            nextPos()
            return
        }
        while let c = nextCharacter() {
            guard !c.isNewline else {
                nextPos()
                return
            }
        }
    }

    func error(message: String) -> CodeReference {
        .init(message: message, line: currentLine, col: currentCol)
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
