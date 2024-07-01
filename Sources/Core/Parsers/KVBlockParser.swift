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

        return .withErrors(warnings: [], errors: [position.error(message: "Not implemented")])
    }

    private mutating func parseLine(_ data: DataSource) -> KVBlock.KVLine? {
        guard let _ = data.nextCharacter() else { return nil }

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
    /// Unlike most other parser, quoted string parser does test the next symbol after the closing quotes
    /// In addition, the data source must be pointing at the opening quotation marks before parsing
    func parse(_ data: DataSource) -> ParseResult<String> {
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
                return .withSuccess(result: buffer, warnings: warnings)
            }
        }

        return .withErrors(warnings: controlCharactersDetected ? warnings : [], errors: [
            startPosition.error(message: "End of stream is encountered before the end of quoted string"),
        ])
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
        case dot
        case digit(Character)
    }

    enum Output: Equatable {
        case integer(Int)
        case double(Double)
    }

    func parse(_ data: DataSource, firstCharacter: FirstCharacterType) -> ParseResult<Output> {
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

extension KVBlockParser.ValueParser.BoolParser {
    enum FirstCharacterType {
        case t, f
    }

    func parse(_ data: DataSource, firstCharacter: FirstCharacterType) -> ParseResult<Bool> {
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

extension KVBlockParser.ValueParser.EnvParser {
    func parse(_ data: DataSource) -> ParseResult<String> {
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

        let content = KVBlockParser.ValueParser.QuotedStringParser().parse(data)

        guard case let .withSuccess(content, warnings) = content else {
            let warnings = content.warnings
            let errors = [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable name value"),
            ] + content.errors

            return .withErrors(warnings: warnings, errors: errors)
        }

        data.skipWhiteSpaces()

        guard let c6 = data.currentCharacter, c6 == ")" else {
            return .withErrors(warnings: warnings, errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        guard let c7 = data.nextCharacter() else { return .withSuccess(result: content, warnings: warnings) }

        guard c7 == " " || c7 == "/" || c7.isNewline else {
            return .withErrors(warnings: warnings, errors: [
                data.error(message: "Unexpected symbol encoutnered while parsing an environment variable value"),
            ])
        }

        return .withSuccess(result: content, warnings: warnings)
    }
}

extension KVBlock.KVLine.Value: Equatable {}
extension KVBlock.KVLine: Equatable {}
extension KVBlock: Equatable {}
