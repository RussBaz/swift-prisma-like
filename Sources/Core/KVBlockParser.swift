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

    mutating func parse(_ data: DataSource) -> KVBlock? {
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
}

extension KVBlock.KVLine.Value: Equatable {}
extension KVBlock.KVLine: Equatable {}
extension KVBlock: Equatable {}
