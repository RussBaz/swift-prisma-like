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

        case parsingNegativeNumber
        case parsingPositiveNumber
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
}

extension KVBlockParser.ValueParser.QuotedStringParser {
    enum State {
        case normal
        case possiblyQuoted
    }

    func parse(_ data: DataSource) -> String? {
        var state: State = .normal
        var buffer = ""

        while let c = data.nextCharacter() {
            guard !c.isNewline else { return nil }

            switch state {
            case .normal:
                switch c {
                case "\\":
                    state = .possiblyQuoted
                case "\"":
                    return buffer
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
        }

        return nil
    }
}

extension KVBlockParser.ValueParser.NumberParser {}
extension KVBlockParser.ValueParser.BoolParser {}
extension KVBlockParser.ValueParser.EnvParser {}

extension KVBlock.KVLine.Value: Equatable {}
extension KVBlock.KVLine: Equatable {}
extension KVBlock: Equatable {}
