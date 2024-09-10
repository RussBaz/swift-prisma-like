protocol ParserMessage {
    var reason: String { get }
    var message: String { get }
}

extension ParserMessage {
    var message: String { reason }
}

extension KVBlock.Parser.ValueParser.BoolParser.Problem: ParserMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        }
    }
}

extension KVBlock.Parser.ValueParser.QuotedStringParser.Problem: ParserMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case .newLine: "Unexpected end of line"
        case .controlCharacter: "Skipped unexpected control character"
        }
    }
}

extension KVBlock.Parser.ValueParser.EnvParser.Problem: ParserMessage {
    var reason: String {
        switch self {
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .quotedStringProblem: "Inner quoted string value parsing failed"
        }
    }
}

extension KVBlock.Parser.ValueParser.NumberParser.Problem: ParserMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .integerInsteadOfDouble: "Received an Integer number but a Double number was expected"
        }
    }
}

extension KVBlock.Parser.ValueParser.Problem: ParserMessage {
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

extension KVBlock.Parser.KeyParser.Problem: ParserMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case let .missingEqualsSign(c): "Expected \"=\" but encountered \"\(c)\""
        }
    }
}

extension KVBlock.Parser.KeyValueParser.Problem: ParserMessage {
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

extension KVBlock.Parser.Problem: ParserMessage {
    var reason: String {
        switch self {
        case .endOfStream: "Unexpected end of stream"
        case let .unexpectedSymbol(c): "Unexpected character \"\(c)\""
        case .keyValueProble: "Inner key-value parsing failed"
        case .commentProblem: "Inner comment parsing failed"
        }
    }
}
