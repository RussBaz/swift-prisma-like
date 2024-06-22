import Foundation

// enum State {
//     case lookingForBlock
//     case parsingDatasource
//     case parsingGenerator
//     case parsingModel
//     case parsingEnum
// }

struct KVBlock {
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

struct KVBlockParser: Parser {
    let name: String
    let blockComments: [String]

    var nextKey: String
    var nextValue: String
    var nextComment: String
    var accumulatedComments: [String]
    var envVariable: Bool

    var state: State

    var lines: [KVBlock.KVLine]

    init(name blockName: String, comments: [String]) {
        name = blockName
        blockComments = comments

        nextKey = ""
        nextValue = ""
        nextComment = ""
        state = .lookingForKey
        lines = []
        accumulatedComments = []
        envVariable = false
    }

    mutating func resetState() {
        nextKey = ""
        nextValue = ""
        nextComment = ""
        state = .lookingForKey
        lines = []
        accumulatedComments = []
        envVariable = false
    }

    mutating func parse(_ data: DataSource) -> ParseResult<KVBlock> {
        let position = data.curentPosition

        return .withErrors(result: nil, errors: [.init(message: "Not implemented", line: 1, col: 1)])
    }

    private mutating func parseLine(_ data: DataSource) -> KVBlock.KVLine? {
        guard let c = data.nextCharacter() else { return nil }

        return nil
    }
}

extension KVBlockParser {
    enum State {
        case lookingForKey
        case parsingKey
        case lookingForKVSeparator
        case parsingKVSeparator // This case is needed to parse triple comments correctly

        case lookingForValue

        case parsingQuotedValue
        case parsingPossiblyEscapedValue

        case parsingNumberOrTextValue
        case parsingWholeNumberPartValue
        case parsingDecimalNumberPartValue

        case parsingBoolOrTextValue
        case parsingTrueValue
        case parsingFalseValue

        case parsingFunctionOrTextValue

        case parsingStringValue
        case parsingNumberValue // Currently only positive intergers are accepted
        case parsingEnvValue
        case lookingForComment
        case lookingForDoubleComment
        case lookingForTripleComment
        case parsingComment
        case parsingError
        case skippingRestOfLine
        case endOfBlock
    }

    struct ValueParser {}
}

extension KVBlockParser.ValueParser {
    enum State {
        case lookingForBeginning

        case parsingQuoted
        // Nested parser will return either nil or string
        // New lines will break it and invisible characters should be skipped

        case parsingNumber
        // Nested parser will return either nil, int number or double number
        // (on success) plus the next state -> slash or other separators

        case parsingBool
        // Nested parser will return either nil or bool
        // (on success) plus the next state -> slash or other separators

        case parsingEnv
        // Nested parser will return either nil or string
        // (on success) plus the next state -> slash or other separators
    }

    struct QuotedStringParser {}
    struct NumberParser {}
    struct BoolParser {}
    struct EnvParser {}

    struct CommentParser {}
}

extension KVBlockParser.ValueParser.QuotedStringParser {
    enum State {
        case normal
        case possiblyQuoted
    }

    /// Extracts the string contents until an unescaped quotation symbol is enountered
    /// It will return 'nil' if the new line or the end of data are encountered before the end of quoted string is reached
    func parse(_ data: DataSource) -> String? {
        var state: State = .normal
        var buffer = ""

        func updateStateAndContinue(with c: Character) -> Bool {
            switch state {
            case .normal:
                switch c {
                case "\\":
                    state = .possiblyQuoted
                case "\"":
                    return false
                case c where c.isControl:
                    ()
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
                default:
                    buffer.append("\\")
                    buffer.append(c)
                }
            }

            return true
        }

        while let c = data.nextCharacter() {
            guard !c.isNewline else { return nil }

            // Because we have discarded the new line characters
            // it will only stop when the closing quotation mark is encoutnered
            guard updateStateAndContinue(with: c) else { return buffer }
        }

        return nil
    }
}

extension KVBlockParser.ValueParser.NumberParser {
    enum State {
        case empty
        case parsingInteger
        case parsingDouble
    }

    enum FirstCharacterType {
        case minus
        case plus
        case digit(Character)
    }

    enum Output: Equatable {
        case integer(Int)
        case double(Double)
    }

    func parse(_ data: DataSource, firstCharacter: FirstCharacterType) -> Output? {
        var state: State = .empty
        var buffer = if case .minus = firstCharacter { "-" } else { "" }

        if case let .digit(c) = firstCharacter, c.isASCIINumber {
            state = .parsingInteger
            buffer.append(c)
        }

        loop: while let c = data.nextCharacter() {
            guard !c.isNewline else { break }

            switch state {
            case .empty:
                switch c {
                case c where c.isASCIINumber:
                    buffer.append(c)
                    state = .parsingInteger
                default:
                    return nil
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
                    return nil
                }
            case .parsingDouble:
                switch c {
                case " ", "/":
                    break loop
                case c where c.isASCIINumber:
                    buffer.append(c)
                default:
                    return nil
                }
            }
        }

        switch state {
        case .empty:
            return nil
        case .parsingInteger:
            guard let integer = Int(buffer) else { return nil }
            return .integer(integer)
        case .parsingDouble:
            guard let double = Double(buffer) else { return nil }
            return .double(double)
        }
    }
}

extension KVBlockParser.ValueParser.BoolParser {
    enum FirstCharacterType {
        case t, f
    }

    func parse(_ data: DataSource, firstCharacter: FirstCharacterType) -> Bool? {
        switch firstCharacter {
        case .t:
            guard let c2 = data.nextCharacter() else { return nil }
            guard c2 == "r" || c2 == "R" else { return nil }

            guard let c3 = data.nextCharacter() else { return nil }
            guard c3 == "u" || c3 == "U" else { return nil }

            guard let c4 = data.nextCharacter() else { return nil }
            guard c4 == "e" || c4 == "E" else { return nil }

            // End of file reached
            guard let nextChar = data.nextCharacter() else { return true }

            switch nextChar {
            case " ", "/", "\n":
                return true
            default:
                return nil
            }
        case .f:
            guard let c2 = data.nextCharacter() else { return nil }
            guard c2 == "a" || c2 == "A" else { return nil }

            guard let c3 = data.nextCharacter() else { return nil }
            guard c3 == "l" || c3 == "L" else { return nil }

            guard let c4 = data.nextCharacter() else { return nil }
            guard c4 == "s" || c4 == "S" else { return nil }

            guard let c5 = data.nextCharacter() else { return nil }
            guard c5 == "e" || c5 == "E" else { return nil }

            // End of file reached
            guard let nextChar = data.nextCharacter() else { return false }

            switch nextChar {
            case " ", "/", "\n":
                return false
            default:
                return nil
            }
        }
    }
}

extension KVBlockParser.ValueParser.EnvParser {}

extension KVBlock.KVLine.Value: Equatable {}
extension KVBlock.KVLine: Equatable {}
extension KVBlock: Equatable {}
