func skipWhiteSpaces(_ data: String, pos: inout String.Index) {
    while true {
        guard pos < data.endIndex else { return }

        let c = data[pos]

        guard c.isWhitespace else { return }

        pos = data.index(after: pos)
    }
}

func skipLine(_ data: String, pos: inout String.Index) {
    while true {
        guard pos < data.endIndex else { break }

        let c = data[pos]
        pos = data.index(after: pos)

        if c.isNewline { break }
    }
}
