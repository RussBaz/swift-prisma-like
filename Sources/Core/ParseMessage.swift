public protocol ParseMessage: Equatable {
    var reason: String { get }
    var message: String { get }
}

extension ParseMessage {
    var message: String { reason }
    func reference(line: Int, col: Int, level: MessageLevel) -> CodeReference<Self> {
        .init(message: self, line: line, col: col, level: level)
    }
}

extension KVBlock.Parser.ValueParser.BoolParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        }
    }
}

extension KVBlock.Parser.ValueParser.QuotedStringParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case .newLine: "Unexpected end of line"
        case .controlCharacter: "Skipped unexpected control character"
        }
    }
}

extension KVBlock.Parser.ValueParser.EnvParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .quotedStringProblem: "Inner quoted string value parsing failed"
        case .endOfStream: "Unexpected end of stream"
        }
    }
}

extension KVBlock.Parser.ValueParser.NumberParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case let .unexpectedSequence(s): "Unexpected string \"\(s)\""
        case .integerInsteadOfDouble: "Received an Integer number but a Double number was expected"
        }
    }
}

extension KVBlock.Parser.CommentsParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .endOfStream: "Unexpected end of stream"
        }
    }
}

extension KVBlock.Parser.ValueParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .boolProblem: "Inner boolean value parsing failed"
        case .envProblem: "Inner environment value parsing failed"
        case .numberProblem: "Inner number value parsing failed"
        case .quotedStringProblem: "Inner quoted string value parsing failed"
        }
    }
}

extension KVBlock.Parser.KeyParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case let .missingEqualsSign(c): "Expected \"=\" but encountered \"\(c)\""
        case .endOfLine: "Unexpected end of line"
        }
    }
}

extension KVBlock.Parser.KeyValueParser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .skippedSymbols: "Skipped unexpected characters after the end of the block"
        case .keyProblem: "Inner key parsing failed"
        case .valueProblem: "Inner value parsing failed"
        case .commentProblem: "Inner comment parsing failed"
        }
    }
}

extension KVBlock.Parser.Problem: ParseMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .keyValueProble: "Inner key-value parsing failed"
        case .commentProblem: "Inner comment parsing failed"
        }
    }
}
