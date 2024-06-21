protocol Parser {
    associatedtype Output

    mutating func parse(_ data: DataSource) -> ParseResult<Output>
}

struct ParseError {
    let message: String
    let line: Int
    let col: Int
}

enum ParseResult<S> {
    case withSuccess(result: S)
    case withWarnings(result: S, warnings: [ParseError])
    case withErrors(result: S?, errors: [ParseError])
}

extension ParseResult: Equatable where S: Equatable {
    static func == (lhs: ParseResult<S>, rhs: ParseResult<S>) -> Bool {
        switch (lhs, rhs) {
        case let (.withSuccess(result: r1), .withSuccess(result: r2)):
            r1 == r2
        case let (.withWarnings(result: r1, warnings: w1), .withWarnings(result: r2, warnings: w2)):
            w1 == w2 && r1 == r2
        case let (.withErrors(result: r1, errors: e1), .withErrors(result: r2, errors: e2)):
            e1 == e2 && r1 == r2
        default:
            false
        }
    }
}

extension ParseError: Equatable {}
