import Foundation

// enum State {
//     case lookingForBlock
//     case parsingDatasource
//     case parsingGenerator
//     case parsingModel
//     case parsingEnum
// }

struct KVBlock {
    enum Parser {}
    struct KVLine {
        enum Value {
            enum FunctionType {
                enum FunctionArg {
                    case positional(value: Value)
                    case keyword(key: String, value: Value)
                }

                case env(key: String)
                case unknown([FunctionArg])
            }

            case text(String)
            case string(String)
            case integer(Int)
            case number(Double)
            case boolean(Bool)
            case env(String)
        }

        let key: String
        let value: Value
        let comments: [String]
    }

    let name: String
    var lines: [KVLine]
    var comments: [String]
}

extension KVBlock.Parser {
    enum ValueParser {}
    enum CommentsParser {}
    enum KeyParser {}
    enum KeyValueParser {}

    enum KVLineResult {
        case newLine(KVLineType)
        case endOfBlock(KVLineType)
    }

    enum KVLineType {
        case comment(String)
        case kv(KVBlock.KVLine)
        case empty
    }

    enum Problem: Equatable {
        case endOfStream
        case unexpectedSymbol(Character)
        case commentProblem
        case keyValueProble
    }

    static func parse(_ data: DataSource, name: String, comments: [String]) -> ParseResult<KVBlock> {
        var running = true
        var messages: [any CodeReferencing] = []
        var lines: [KVBlock.KVLine] = []
        var accumulatedComments: [String] = []

        while running {
            let line = parseLine(data)
            switch line {
            case let .withSuccess(result, innerMessages):
                messages.append(contentsOf: innerMessages)
                switch result {
                case let .endOfBlock(type):
                    running = false
                    switch type {
                    case let .comment(value):
                        accumulatedComments.append(value)
                    case .empty:
                        () // do nothing
                    case let .kv(value):
                        lines.append(.init(key: value.key, value: value.value, comments: accumulatedComments + value.comments))
                        accumulatedComments = []
                    }
                case let .newLine(type):
                    switch type {
                    case let .comment(value):
                        accumulatedComments.append(value)
                    case .empty:
                        () // do nothing
                    case let .kv(value):
                        lines.append(.init(key: value.key, value: value.value, comments: accumulatedComments + value.comments))
                        accumulatedComments = []
                    }
                }
            case let .withErrors(innerMessages):
                running = false
                return .withErrors(messages: messages + innerMessages)
            }
        }

        let r = KVBlock(name: name, lines: lines, comments: comments)

        return .withSuccess(result: r, messages: messages)
    }

    static func parseLine(_ data: DataSource) -> ParseResult<KVLineResult> {
        guard let firstCharacter = data.currentCharacter else {
            return .withErrors(messages: [
                data.error(message: Problem.endOfStream),
            ])
        }

        let c = if firstCharacter == " " {
            data.skipWhiteSpaces()
        } else {
            firstCharacter
        }

        guard let c else {
            return .withErrors(messages: [
                data.error(message: Problem.endOfStream),
            ])
        }

        switch c {
        case "/": // Comment block start found
            let comment = KVBlock.Parser.CommentsParser.parse(data)
            switch comment {
            case let .withSuccess(result, messages):
                if let result {
                    return .withSuccess(result: .newLine(.comment(result)), messages: messages)
                } else {
                    return .withSuccess(result: .newLine(.empty), messages: messages)
                }
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case "\n": // Empty line found
            data.nextPos()
            return .withSuccess(result: .newLine(.empty), messages: [])
        case "}": // End of block found
            data.nextPos()
            return .withSuccess(result: .endOfBlock(.empty), messages: [])
        case c where c.isWord: // Key start found
            let line = KVBlock.Parser.KeyValueParser.parse(data, firstCharacter: c)
            switch line {
            case let .withSuccess(result, messages):
                switch result {
                case let .endOfBlock(line):
                    return .withSuccess(result: .endOfBlock(.kv(line)), messages: messages)
                case let .newLine(line):
                    return .withSuccess(result: .newLine(.kv(line)), messages: messages)
                }
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        default: // Unexpected symbol
            return .withErrors(messages: [
                data.error(message: Problem.unexpectedSymbol(c)),
            ])
        }
    }
}

extension KVBlock.Parser.ValueParser {
    enum QuotedStringParser {}
    enum NumberParser {}
    enum BoolParser {}
    enum EnvParser {}

    enum Problem: Equatable {
        case endOfStream
        case unexpectedSymbol(Character)
        case quotedStringProblem
        case numberProblem
        case boolProblem
        case envProblem
    }

    static func parse(_ data: DataSource) -> ParseResult<KVBlock.KVLine.Value> {
        guard let c = data.currentCharacter else {
            return .withErrors(messages: [data.error(message: Problem.endOfStream)])
        }

        let beginning = data.curentPosition

        switch c {
        case "\"":
            let result = QuotedStringParser.parse(data)
            switch result {
            case let .withSuccess(value, messages):
                return .withSuccess(result: .string(value), messages: messages)
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case "+":
            let result = NumberParser.parse(data, firstCharacter: .plus)
            switch result {
            case let .withSuccess(value, messages):
                switch value {
                case let .integer(value):
                    return .withSuccess(result: .integer(value), messages: messages)
                case let .double(value):
                    return .withSuccess(result: .number(value), messages: messages)
                }
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case "-":
            let result = NumberParser.parse(data, firstCharacter: .minus)
            switch result {
            case let .withSuccess(value, messages):
                switch value {
                case let .integer(value):
                    return .withSuccess(result: .integer(value), messages: messages)
                case let .double(value):
                    return .withSuccess(result: .number(value), messages: messages)
                }
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case ".":
            let result = NumberParser.parse(data, firstCharacter: .dot)
            switch result {
            case .withSuccess(let value, var messages):
                switch value {
                case let .integer(value):
                    messages.append(beginning.error(message: Problem.numberProblem))
                    return .withSuccess(result: .integer(value), messages: messages)
                case let .double(value):
                    return .withSuccess(result: .number(value), messages: messages)
                }
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case c where c.isASCIINumber:
            let result = NumberParser.parse(data, firstCharacter: .digit(c))
            switch result {
            case let .withSuccess(value, messages):
                switch value {
                case let .integer(value):
                    return .withSuccess(result: .integer(value), messages: messages)
                case let .double(value):
                    return .withSuccess(result: .number(value), messages: messages)
                }
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case "t", "T":
            let result = BoolParser.parse(data, firstCharacter: .t)
            switch result {
            case let .withSuccess(value, messages):
                return .withSuccess(result: .boolean(value), messages: messages)
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case "f", "F":
            let result = BoolParser.parse(data, firstCharacter: .f)
            switch result {
            case let .withSuccess(value, messages):
                return .withSuccess(result: .boolean(value), messages: messages)
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        case "e":
            let result = EnvParser.parse(data)
            switch result {
            case let .withSuccess(value, messages):
                return .withSuccess(result: .env(value), messages: messages)
            case let .withErrors(messages):
                return .withErrors(messages: messages)
            }
        default:
            return .withErrors(messages: [
                data.error(message: Problem.unexpectedSymbol(c)),
            ])
        }
    }
}

extension KVBlock.Parser.ValueParser.QuotedStringParser {
    enum State {
        case normal
        case possiblyQuoted
    }

    enum Problem: Equatable {
        case controlCharacter
        case newLine
        case endOfStream
    }

    /// Extracts the string contents until an unescaped quotation symbol is enountered
    /// It will return 'nil' if the new line or the end of data are encountered before the end of quoted string is reached
    /// Unlike most other parser, quoted string parser does not test the next symbol after the closing quotes
    /// In addition, the data source must be pointing at the opening quotation marks before parsing
    static func parse(_ data: DataSource) -> ParseResult<String> {
        var state: State = .normal
        var buffer = ""

        var controlCharactersDetected = false
        let startPosition = data.curentPosition

        func updateStateAndContinue(with c: Character) -> Bool {
            switch state {
            case .normal:
                switch c {
                case "\\":
                    state = .possiblyQuoted
                case "\"":
                    return false
                case c where c.isControl:
                    controlCharactersDetected = true
                default:
                    buffer.append(c)
                }
            case .possiblyQuoted:
                state = .normal

                switch c {
                case "\"":
                    buffer.append("\"")
                case c where c.isControl:
                    buffer.append("\\")
                    controlCharactersDetected = true
                default:
                    buffer.append("\\")
                    buffer.append(c)
                }
            }

            return true
        }

        while let c = data.nextCharacter() {
            guard !c.isNewline else {
                let messages: [CodeReference<Problem>] = if controlCharactersDetected {
                    [
                        startPosition.warning(message: .controlCharacter),
                        data.error(message: .newLine),
                    ]
                } else {
                    [
                        data.error(message: .newLine),
                    ]
                }
                return .withErrors(messages: messages)
            }

            // Because we have discarded the new line characters
            // it will only stop when the closing quotation mark is encoutnered
            guard updateStateAndContinue(with: c) else {
                let messages: [CodeReference<Problem>] = if controlCharactersDetected {
                    [startPosition.warning(message: .controlCharacter)]
                } else {
                    []
                }
                data.nextPos()
                return .withSuccess(result: buffer, messages: messages)
            }
        }

        return .withErrors(messages:
            controlCharactersDetected ?
                [
                    startPosition.warning(message: Problem.controlCharacter),
                    data.error(message: Problem.endOfStream),
                ] : [
                    data.error(message: Problem.endOfStream),
                ]
        )
    }
}

extension KVBlock.Parser.ValueParser.NumberParser {
    enum State {
        case empty
        case parsingInteger
        case parsingDouble
    }

    enum Problem: Equatable {
        case integerInsteadOfDouble
        case unexpectedSymbol(Character)
        case unexpectedSequence(String)
        case endOfStream
    }

    enum FirstCharacterType {
        case minus
        case plus
        case dot
        case digit(Character)
    }

    enum Output: Equatable {
        case integer(Int)
        case double(Double)
    }

    static func parse(_ data: DataSource, firstCharacter: FirstCharacterType) -> ParseResult<Output> {
        var state: State = .empty
        var buffer = if case .minus = firstCharacter { "-" } else { "" }

        if case let .digit(c) = firstCharacter, c.isASCIINumber {
            state = .parsingInteger
            buffer.append(c)
        } else if case .dot = firstCharacter {
            buffer.append(contentsOf: "0.")
            state = .parsingDouble
        }

        loop: while let c = data.nextCharacter() {
            guard !c.isNewline else { break }

            switch state {
            case .empty:
                switch c {
                case ".":
                    buffer.append(contentsOf: "0.")
                    state = .parsingDouble
                case c where c.isASCIINumber:
                    buffer.append(c)
                    state = .parsingInteger
                default:
                    return .withErrors(messages: [data.error(message: Problem.unexpectedSymbol(c))])
                }
            case .parsingInteger:
                switch c {
                case ".":
                    buffer.append(c)
                    state = .parsingDouble
                case " ", "/":
                    break loop
                case c where c.isASCIINumber:
                    buffer.append(c)
                default:
                    return .withErrors(messages: [data.error(message: Problem.unexpectedSymbol(c))])
                }
            case .parsingDouble:
                switch c {
                case " ", "/":
                    break loop
                case c where c.isASCIINumber:
                    buffer.append(c)
                default:
                    return .withErrors(messages: [data.error(message: Problem.unexpectedSymbol(c))])
                }
            }
        }

        switch state {
        case .empty:
            return .withErrors(messages: [data.error(message: Problem.endOfStream)])
        case .parsingInteger:
            guard let integer = Int(buffer) else {
                return .withErrors(messages: [data.error(message: Problem.unexpectedSequence(buffer))])
            }
            return .withSuccess(result: .integer(integer), messages: [])
        case .parsingDouble:
            guard let double = Double(buffer) else {
                return .withErrors(messages: [data.error(message: Problem.unexpectedSequence(buffer))])
            }
            return .withSuccess(result: .double(double), messages: [])
        }
    }
}

extension KVBlock.Parser.ValueParser.BoolParser {
    enum FirstCharacterType {
        case t, f
    }

    enum Problem: Equatable {
        case unexpectedSymbol(Character)
        case endOfStream
    }

    static func parse(_ data: DataSource, firstCharacter: FirstCharacterType) -> ParseResult<Bool> {
        switch firstCharacter {
        case .t:
            guard let c2 = data.nextCharacter() else {
                return .withErrors(messages: [
                    data.error(message: Problem.endOfStream),
                ])
            }
            guard c2 == "r" || c2 == "R" else {
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c2)),
                ])
            }

            guard let c3 = data.nextCharacter() else {
                return .withErrors(messages: [
                    data.error(message: Problem.endOfStream),
                ])
            }
            guard c3 == "u" || c3 == "U" else {
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c3)),
                ])
            }

            guard let c4 = data.nextCharacter() else {
                return .withErrors(messages: [
                    data.error(message: Problem.endOfStream),
                ])
            }
            guard c4 == "e" || c4 == "E" else {
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c4)),
                ])
            }

            // End of file reached
            guard let nextChar = data.nextCharacter() else { return .withSuccess(result: true, messages: []) }

            switch nextChar {
            case " ", "/":
                return .withSuccess(result: true, messages: [])
            case nextChar where nextChar.isNewline:
                return .withSuccess(result: true, messages: [])
            default:
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(nextChar)),
                ])
            }
        case .f:
            guard let c2 = data.nextCharacter() else {
                return .withErrors(messages: [
                    data.error(message: Problem.endOfStream),
                ])
            }
            guard c2 == "a" || c2 == "A" else {
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c2)),
                ])
            }

            guard let c3 = data.nextCharacter() else {
                return .withErrors(messages: [
                    data.error(message: Problem.endOfStream),
                ])
            }
            guard c3 == "l" || c3 == "L" else {
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c3)),
                ])
            }

            guard let c4 = data.nextCharacter() else {
                return .withErrors(messages: [
                    data.error(message: Problem.endOfStream),
                ])
            }
            guard c4 == "s" || c4 == "S" else {
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c4)),
                ])
            }

            guard let c5 = data.nextCharacter() else {
                return .withErrors(messages: [
                    data.error(message: Problem.endOfStream),
                ])
            }
            guard c5 == "e" || c5 == "E" else {
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c5)),
                ])
            }

            // End of file reached
            guard let nextChar = data.nextCharacter() else { return .withSuccess(result: false, messages: []) }

            switch nextChar {
            case " ", "/":
                return .withSuccess(result: false, messages: [])
            case nextChar where nextChar.isNewline:
                return .withSuccess(result: false, messages: [])
            default:
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(nextChar)),
                ])
            }
        }
    }
}

extension KVBlock.Parser.ValueParser.EnvParser {
    enum Problem: Equatable {
        case unexpectedSymbol(Character)
        case quotedStringProblem
        case endOfStream
    }

    static func parse(_ data: DataSource) -> ParseResult<String> {
        guard let c2 = data.nextCharacter() else {
            return .withErrors(messages: [
                data.error(message: Problem.endOfStream),
            ])
        }

        guard c2 == "n" else {
            return .withErrors(messages: [
                data.error(message: Problem.unexpectedSymbol(c2)),
            ])
        }

        guard let c3 = data.nextCharacter() else {
            return .withErrors(messages: [
                data.error(message: Problem.endOfStream),
            ])
        }

        guard c3 == "v" else {
            return .withErrors(messages: [
                data.error(message: Problem.unexpectedSymbol(c3)),
            ])
        }

        guard let c4 = data.nextCharacter() else {
            return .withErrors(messages: [
                data.error(message: Problem.endOfStream),
            ])
        }

        guard c4 == "(" else {
            return .withErrors(messages: [
                data.error(message: Problem.unexpectedSymbol(c4)),
            ])
        }

        data.skipWhiteSpaces()

        guard let c5 = data.currentCharacter else {
            return .withErrors(messages: [
                data.error(message: Problem.endOfStream),
            ])
        }

        guard c5 == "\"" else {
            return .withErrors(messages: [
                data.error(message: Problem.unexpectedSymbol(c5)),
            ])
        }

        let content = KVBlock.Parser.ValueParser.QuotedStringParser.parse(data)

        guard case let .withSuccess(content, messages) = content else {
            return .withErrors(messages: content.messages)
        }

        if let c = data.currentCharacter, c.isSpace {
            data.skipWhiteSpaces()
        }

        guard let c6 = data.currentCharacter else {
            return .withErrors(messages: messages + data.error(message: Problem.endOfStream))
        }

        guard c6 == ")" else {
            return .withErrors(messages: messages + data.error(message: Problem.unexpectedSymbol(c6)))
        }

        guard let c7 = data.nextCharacter() else {
            return .withErrors(messages: messages + data.error(message: Problem.endOfStream))
        }

        guard c7 == " " || c7 == "/" || c7 == "\n" || c7 == "}" else {
            return .withErrors(messages: messages + data.error(message: Problem.unexpectedSymbol(c7)))
        }

        return .withSuccess(result: content, messages: messages)
    }
}

extension KVBlock.Parser.CommentsParser {
    enum Problem: Equatable {
        case unexpectedSymbol(Character)
        case endOfStream
    }

    static func parse(_ data: DataSource) -> ParseResult<String?> {
        guard let first = data.nextCharacter() else {
            return .withErrors(messages: [
                data.error(message: Problem.endOfStream),
            ])
        }

        guard first == "/" else {
            return .withErrors(messages: [
                data.error(message: Problem.unexpectedSymbol(first)),
            ])
        }

        guard let second = data.nextCharacter() else {
            return .withSuccess(result: nil, messages: [])
        }

        guard second == "/" else {
            data.skipLine()
            return .withSuccess(result: nil, messages: [])
        }

        data.nextPos()

        let buffer = data.skipLine().trimmingCharacters(in: .whitespaces)

        return .withSuccess(result: buffer, messages: [])
    }
}

extension KVBlock.Parser.KeyParser {
    enum Problem: Equatable {
        case missingEqualsSign(Character)
        case unexpectedSymbol(Character)
        case endOfStream
        case endOfLine
    }

    static func parse(_ data: DataSource, firstCharacter: Character) -> ParseResult<String> {
        var buffer = "\(firstCharacter)"

        while let c = data.nextCharacter() {
            switch c {
            case " ":
                guard let next = data.skipWhiteSpaces() else {
                    return .withErrors(messages: [
                        data.error(message: Problem.endOfStream),
                    ])
                }
                guard next == "=" else {
                    return .withErrors(messages: [
                        data.error(message: Problem.missingEqualsSign(next)),
                    ])
                }
                data.nextPos()
                return .withSuccess(result: buffer, messages: [])
            case "=":
                data.nextPos()
                return .withSuccess(result: buffer, messages: [])
            case "\n":
                return .withErrors(messages: [
                    data.error(message: Problem.endOfLine),
                ])
            case c where c.isWord:
                buffer.append(c)
            default:
                return .withErrors(messages: [
                    data.error(message: Problem.unexpectedSymbol(c)),
                ])
            }
        }

        return .withErrors(messages: [
            data.error(message: Problem.endOfStream),
        ])
    }
}

extension KVBlock.Parser.KeyValueParser {
    enum KVLineResult {
        case newLine(KVBlock.KVLine)
        case endOfBlock(KVBlock.KVLine)
    }

    enum Problem: Equatable {
        case endOfStream
        case unexpectedSymbol(Character)
        case skippedSymbols
        case keyProblem
        case valueProblem
        case commentProblem
    }

    static func parse(_ data: DataSource, firstCharacter: Character) -> ParseResult<KVLineResult> {
        let key = KVBlock.Parser.KeyParser.parse(data, firstCharacter: firstCharacter)

        guard case let .withSuccess(keyContent, keyMessages) = key else {
            return .withErrors(messages: key.messages)
        }

        if let c = data.currentCharacter, c.isSpace {
            data.skipWhiteSpaces()
        }

        let value = KVBlock.Parser.ValueParser.parse(data)

        guard case let .withSuccess(valueContent, valueMessages) = value else {
            return .withErrors(messages: keyMessages + value.messages)
        }

        var messages = keyMessages + valueMessages

        if let c = data.currentCharacter, c.isSpace {
            data.skipWhiteSpaces()
        }

        guard let c = data.currentCharacter else {
            return .withErrors(messages: messages + data.error(message: Problem.endOfStream))
        }

        switch c {
        case "\n":
            data.nextPos()
            return .withSuccess(result: .newLine(.init(key: keyContent, value: valueContent)), messages: messages)
        case "}":
            let next = data.nextCharacter()
            guard next == nil || next == "\n" || next == " " else {
                return .withErrors(messages: messages + data.error(message: Problem.unexpectedSymbol(next!)))
            }

            switch next {
            case nil:
                return .withSuccess(result: .endOfBlock(.init(key: keyContent, value: valueContent)), messages: messages)
            case "\n":
                data.nextPos()
                return .withSuccess(result: .endOfBlock(.init(key: keyContent, value: valueContent)), messages: messages)
            case " ":
                if let c = data.skipWhiteSpaces() {
                    if c == "\n" {
                        data.nextPos()
                    } else {
                        messages = messages + data.warning(message: Problem.skippedSymbols)
                        data.skipLine()
                    }
                }

                return .withSuccess(result: .endOfBlock(.init(key: keyContent, value: valueContent)), messages: messages)
            default:
                return .withErrors(messages: messages + data.error(message: Problem.unexpectedSymbol(next!)))
            }
        case "/":
            let comment = KVBlock.Parser.CommentsParser.parse(data)
            switch comment {
            case let .withSuccess(result, commentMessages):
                let result: [String]? = if let result { [result] } else { nil }
                return .withSuccess(result: .newLine(.init(key: keyContent, value: valueContent, comments: result)), messages: messages + commentMessages)
            case let .withErrors(commentMessages):
                return .withErrors(messages: messages + commentMessages)
            }
        default:
            return .withErrors(messages: messages + data.error(message: Problem.unexpectedSymbol(c)))
        }
    }
}

extension KVBlock.KVLine {
    init(key: String, value: KVBlock.KVLine.Value, comments: [String]? = nil) {
        self.key = key
        self.value = value
        self.comments = comments ?? []
    }
}

extension KVBlock.KVLine.Value: Equatable {}
extension KVBlock.KVLine: Equatable {}
extension KVBlock: Equatable {}
extension KVBlock.Parser.KVLineResult: Equatable {}
extension KVBlock.Parser.KVLineType: Equatable {}
extension KVBlock.Parser.KeyValueParser.KVLineResult: Equatable {}
