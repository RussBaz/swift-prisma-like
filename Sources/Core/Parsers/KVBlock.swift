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

    static func parse(_ data: DataSource, name: String, comments: [String]) -> ParseResult<KVBlock> {
        var running = true
        var warnings: [CodeReference] = []
        var lines: [KVBlock.KVLine] = []
        var accumulatedComments: [String] = []

        while running {
            let line = parseLine(data)
            switch line {
            case let .withSuccess(result, innerWarnings):
                warnings.append(contentsOf: innerWarnings)
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
            case let .withErrors(innerWarnings, errors):
                running = false
                return .withErrors(warnings: warnings + innerWarnings, errors: errors)
            }
        }

        let r = KVBlock(name: name, lines: lines, comments: comments)

        return .withSuccess(result: r, warnings: warnings)
    }

    static func parseLine(_ data: DataSource) -> ParseResult<KVLineResult> {
        guard let firstCharacter = data.currentCharacter else {
            return .withErrors(warnings: [], errors: [data.error(message: "Unexpected end of stream encountered while parsing a KV block line")])
        }

        let c = if firstCharacter == " " {
            data.skipWhiteSpaces()
        } else {
            firstCharacter
        }

        guard let c else {
            return .withErrors(warnings: [], errors: [data.error(message: "Unexpected end of stream encountered while parsing a KV block line")])
        }

        switch c {
        case "/": // Comment block start found
            let comment = KVBlock.Parser.CommentsParser.parse(data)
            switch comment {
            case let .withSuccess(result, warnings):
                if let result {
                    return .withSuccess(result: .newLine(.comment(result)), warnings: warnings)
                } else {
                    return .withSuccess(result: .newLine(.empty), warnings: warnings)
                }
            case let .withErrors(warnings, errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case "\n": // Empty line found
            data.nextPos()
            return .withSuccess(result: .newLine(.empty), warnings: [])
        case "}": // End of block found
            data.nextPos()
            return .withSuccess(result: .endOfBlock(.empty), warnings: [])
        case c where c.isWord: // Key start found
            let line = KVBlock.Parser.KeyValueParser.parse(data, firstCharacter: c)
            switch line {
            case let .withSuccess(result, warnings):
                switch result {
                case let .endOfBlock(line):
                    return .withSuccess(result: .endOfBlock(.kv(line)), warnings: warnings)
                case let .newLine(line):
                    return .withSuccess(result: .newLine(.kv(line)), warnings: warnings)
                }
            case let .withErrors(warnings, errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        default: // Unexpected symbol
            return .withErrors(warnings: [], errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing a KV block line"),
            ])
        }
    }
}

extension KVBlock.Parser.ValueParser {
    enum QuotedStringParser {}
    enum NumberParser {}
    enum BoolParser {}
    enum EnvParser {}

    static func parse(_ data: DataSource) -> ParseResult<KVBlock.KVLine.Value> {
        guard let c = data.currentCharacter else {
            return .withErrors(warnings: [], errors: [
                data.error(message: "Unexpected end of stream encountered while parsing a KV block line value"),
            ])
        }

        let beginning = data.curentPosition

        switch c {
        case "\"":
            let result = QuotedStringParser.parse(data)
            switch result {
            case let .withSuccess(result: value, warnings: warnings):
                return .withSuccess(result: .string(value), warnings: warnings)
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case "+":
            let result = NumberParser.parse(data, firstCharacter: .plus)
            switch result {
            case let .withSuccess(result: value, warnings: warnings):
                switch value {
                case let .integer(value):
                    return .withSuccess(result: .integer(value), warnings: warnings)
                case let .double(value):
                    return .withSuccess(result: .number(value), warnings: warnings)
                }
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case "-":
            let result = NumberParser.parse(data, firstCharacter: .minus)
            switch result {
            case let .withSuccess(result: value, warnings: warnings):
                switch value {
                case let .integer(value):
                    return .withSuccess(result: .integer(value), warnings: warnings)
                case let .double(value):
                    return .withSuccess(result: .number(value), warnings: warnings)
                }
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case ".":
            let result = NumberParser.parse(data, firstCharacter: .dot)
            switch result {
            case .withSuccess(result: let value, warnings: var warnings):
                switch value {
                case let .integer(value):
                    warnings.append(beginning.error(message: "Expected a floating point number but an integer was received."))
                    return .withSuccess(result: .integer(value), warnings: warnings)
                case let .double(value):
                    return .withSuccess(result: .number(value), warnings: warnings)
                }
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case c where c.isASCIINumber:
            let result = NumberParser.parse(data, firstCharacter: .digit(c))
            switch result {
            case let .withSuccess(result: value, warnings: warnings):
                switch value {
                case let .integer(value):
                    return .withSuccess(result: .integer(value), warnings: warnings)
                case let .double(value):
                    return .withSuccess(result: .number(value), warnings: warnings)
                }
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case "t", "T":
            let result = BoolParser.parse(data, firstCharacter: .t)
            switch result {
            case let .withSuccess(result: value, warnings: warnings):
                return .withSuccess(result: .boolean(value), warnings: warnings)
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case "f", "F":
            let result = BoolParser.parse(data, firstCharacter: .f)
            switch result {
            case let .withSuccess(result: value, warnings: warnings):
                return .withSuccess(result: .boolean(value), warnings: warnings)
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        case "e":
            let result = EnvParser.parse(data)
            switch result {
            case let .withSuccess(result: value, warnings: warnings):
                return .withSuccess(result: .env(value), warnings: warnings)
            case let .withErrors(warnings: warnings, errors: errors):
                return .withErrors(warnings: warnings, errors: errors)
            }
        default:
            return .withErrors(warnings: [], errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing a KV block line value"),
            ])
        }
    }
}

extension KVBlock.Parser.ValueParser.QuotedStringParser {
    enum State {
        case normal
        case possiblyQuoted
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
        let warnings: [CodeReference] = [
            startPosition.error(message: "Control characters were detected and skipped in the quoted string"),
        ]

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
                let warnings: [CodeReference] = if controlCharactersDetected {
                    warnings
                } else {
                    []
                }
                return .withErrors(warnings: warnings, errors: [data.error(message: "New lines are not allowed inside the quoted strings")])
            }

            // Because we have discarded the new line characters
            // it will only stop when the closing quotation mark is encoutnered
            guard updateStateAndContinue(with: c) else {
                let warnings: [CodeReference] = if controlCharactersDetected {
                    warnings
                } else {
                    []
                }
                data.nextPos()
                return .withSuccess(result: buffer, warnings: warnings)
            }
        }

        return .withErrors(warnings: controlCharactersDetected ? warnings : [], errors: [
            startPosition.error(message: "End of stream is encountered before the end of quoted string"),
        ])
    }
}

extension KVBlock.Parser.ValueParser.NumberParser {
    enum State {
        case empty
        case parsingInteger
        case parsingDouble
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
                    return .withErrors(warnings: [], errors: [
                        data.error(message: "Non-numerical symbol encountered while parsing a number"),
                    ])
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
                    return .withErrors(warnings: [], errors: [
                        data.error(message: "Non-numerical symbol encountered while parsing a number"),
                    ])
                }
            case .parsingDouble:
                switch c {
                case " ", "/":
                    break loop
                case c where c.isASCIINumber:
                    buffer.append(c)
                default:
                    return .withErrors(warnings: [], errors: [
                        data.error(message: "Non-numerical symbol encountered while parsing a number"),
                    ])
                }
            }
        }

        switch state {
        case .empty:
            return .withErrors(warnings: [], errors: [
                data.error(message: "End of stream encountered before any numerical symbol"),
            ])
        case .parsingInteger:
            guard let integer = Int(buffer) else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Non-numerical symbol encountered while parsing a number"),
                ])
            }
            return .withSuccess(result: .integer(integer), warnings: [])
        case .parsingDouble:
            guard let double = Double(buffer) else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Non-numerical symbol encountered while parsing a number"),
                ])
            }
            return .withSuccess(result: .double(double), warnings: [])
        }
    }
}

extension KVBlock.Parser.ValueParser.BoolParser {
    enum FirstCharacterType {
        case t, f
    }

    static func parse(_ data: DataSource, firstCharacter: FirstCharacterType) -> ParseResult<Bool> {
        switch firstCharacter {
        case .t:
            guard let c2 = data.nextCharacter() else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of stream encountered while parsing a boolean value"),
                ])
            }
            guard c2 == "r" || c2 == "R" else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }

            guard let c3 = data.nextCharacter() else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of stream encountered while parsing a boolean value"),
                ])
            }
            guard c3 == "u" || c3 == "U" else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }

            guard let c4 = data.nextCharacter() else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of stream encountered while parsing a boolean value"),
                ])
            }
            guard c4 == "e" || c4 == "E" else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }

            // End of file reached
            guard let nextChar = data.nextCharacter() else { return .withSuccess(result: true, warnings: []) }

            switch nextChar {
            case " ", "/":
                return .withSuccess(result: true, warnings: [])
            case nextChar where nextChar.isNewline:
                return .withSuccess(result: true, warnings: [])
            default:
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }
        case .f:
            guard let c2 = data.nextCharacter() else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of stream encountered while parsing a boolean value"),
                ])
            }
            guard c2 == "a" || c2 == "A" else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }

            guard let c3 = data.nextCharacter() else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of stream encountered while parsing a boolean value"),
                ])
            }
            guard c3 == "l" || c3 == "L" else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }

            guard let c4 = data.nextCharacter() else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of stream encountered while parsing a boolean value"),
                ])
            }
            guard c4 == "s" || c4 == "S" else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }

            guard let c5 = data.nextCharacter() else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of stream encountered while parsing a boolean value"),
                ])
            }
            guard c5 == "e" || c5 == "E" else {
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }

            // End of file reached
            guard let nextChar = data.nextCharacter() else { return .withSuccess(result: false, warnings: []) }

            switch nextChar {
            case " ", "/":
                return .withSuccess(result: false, warnings: [])
            case nextChar where nextChar.isNewline:
                return .withSuccess(result: false, warnings: [])
            default:
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a boolean value"),
                ])
            }
        }
    }
}

extension KVBlock.Parser.ValueParser.EnvParser {
    static func parse(_ data: DataSource) -> ParseResult<String> {
        guard let c2 = data.nextCharacter(), c2 == "n" else {
            return .withErrors(warnings: [], errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        guard let c3 = data.nextCharacter(), c3 == "v" else {
            return .withErrors(warnings: [], errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        guard let c4 = data.nextCharacter(), c4 == "(" else {
            return .withErrors(warnings: [], errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        data.skipWhiteSpaces()

        guard let c5 = data.currentCharacter, c5 == "\"" else {
            return .withErrors(warnings: [], errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        let content = KVBlock.Parser.ValueParser.QuotedStringParser.parse(data)

        guard case let .withSuccess(content, warnings) = content else {
            let warnings = content.warnings
            let errors = content.errors + [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable name value"),
            ]

            return .withErrors(warnings: warnings, errors: errors)
        }

        if let c = data.currentCharacter, c.isSpace {
            data.skipWhiteSpaces()
        }

        guard let c6 = data.currentCharacter, c6 == ")" else {
            return .withErrors(warnings: warnings, errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        guard let c7 = data.nextCharacter() else { return .withSuccess(result: content, warnings: warnings) }

        guard c7 == " " || c7 == "/" || c7 == "\n" || c7 == "}" else {
            return .withErrors(warnings: warnings, errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        return .withSuccess(result: content, warnings: warnings)
    }
}

extension KVBlock.Parser.CommentsParser {
    static func parse(_ data: DataSource) -> ParseResult<String?> {
        let first = data.nextCharacter()

        guard first == "/" else {
            return .withErrors(warnings: [], errors: [data.error(message: "Unexpected symbol encoutnered while parsing a comment opening")])
        }

        let second = data.nextCharacter()

        guard let second else {
            return .withSuccess(result: nil, warnings: [])
        }

        guard second == "/" else {
            data.skipLine()
            return .withSuccess(result: nil, warnings: [])
        }

        data.nextPos()

        let buffer = data.skipLine().trimmingCharacters(in: .whitespaces)

        return .withSuccess(result: buffer, warnings: [])
    }
}

extension KVBlock.Parser.KeyParser {
    static func parse(_ data: DataSource, firstCharacter: Character) -> ParseResult<String> {
        var buffer = "\(firstCharacter)"

        while let c = data.nextCharacter() {
            switch c {
            case " ":
                let next = data.skipWhiteSpaces()
                guard next == "=" else {
                    return .withErrors(warnings: [], errors: [
                        data.error(message: "Unexpected symbol encoutnered while looking for '=' sign"),
                    ])
                }
                data.nextPos()
                return .withSuccess(result: buffer, warnings: [])
            case "=":
                data.nextPos()
                return .withSuccess(result: buffer, warnings: [])
            case "\n":
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected end of line encoutnered while parsing a key value"),
                ])
            case c where c.isWord:
                buffer.append(c)
            default:
                return .withErrors(warnings: [], errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a key value"),
                ])
            }
        }

        return .withErrors(warnings: [], errors: [
            data.error(message: "Unexpected end of stream encountered while parsing a key value"),
        ])
    }
}

extension KVBlock.Parser.KeyValueParser {
    enum KVLineResult {
        case newLine(KVBlock.KVLine)
        case endOfBlock(KVBlock.KVLine)
    }

    static func parse(_ data: DataSource, firstCharacter: Character) -> ParseResult<KVLineResult> {
        let key = KVBlock.Parser.KeyParser.parse(data, firstCharacter: firstCharacter)

        guard case let .withSuccess(keyContent, warnings) = key else {
            return .withErrors(warnings: key.warnings, errors: key.errors)
        }

        var allWarnings = warnings

        if let c = data.currentCharacter, c.isSpace {
            data.skipWhiteSpaces()
        }

        let value = KVBlock.Parser.ValueParser.parse(data)

        guard case let .withSuccess(valueContent, warnings) = value else {
            return .withErrors(warnings: allWarnings + value.warnings, errors: value.errors)
        }

        allWarnings.append(contentsOf: warnings)

        if let c = data.currentCharacter, c.isSpace {
            data.skipWhiteSpaces()
        }

        guard let c = data.currentCharacter else {
            return .withErrors(warnings: allWarnings, errors: [
                data.error(message: "Unexpected end of stream encountered while parsing a KV line"),
            ])
        }

        switch c {
        case "\n":
            data.nextPos()
            return .withSuccess(result: .newLine(.init(key: keyContent, value: valueContent)), warnings: allWarnings)
        case "}":
            let next = data.nextCharacter()
            guard next == nil || next == "\n" || next == " " else {
                return .withErrors(warnings: allWarnings, errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a KV line"),
                ])
            }
            switch next {
            case nil:
                return .withSuccess(result: .endOfBlock(.init(key: keyContent, value: valueContent)), warnings: allWarnings)
            case "\n":
                data.nextPos()
                return .withSuccess(result: .endOfBlock(.init(key: keyContent, value: valueContent)), warnings: allWarnings)
            case " ":
                if let c = data.skipWhiteSpaces() {
                    if c == "\n" {
                        data.nextPos()
                    } else {
                        allWarnings.append(data.error(message: "Unexpected symbols encountered and skipped after parsing a KV line"))
                        data.skipLine()
                    }
                }

                return .withSuccess(result: .endOfBlock(.init(key: keyContent, value: valueContent)), warnings: allWarnings)
            default:
                return .withErrors(warnings: allWarnings, errors: [
                    data.error(message: "Unexpected symbol encoutnered while parsing a KV line"),
                ])
            }
        case "/":
            let comment = KVBlock.Parser.CommentsParser.parse(data)
            switch comment {
            case let .withSuccess(result, warnings):
                let result: [String]? = if let result { [result] } else { nil }
                return .withSuccess(result: .newLine(.init(key: keyContent, value: valueContent, comments: result)), warnings: allWarnings + warnings)
            case let .withErrors(warnings, errors):
                return .withErrors(warnings: allWarnings + warnings, errors: errors)
            }
        default:
            return .withErrors(warnings: allWarnings, errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing a KV line"),
            ])
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
