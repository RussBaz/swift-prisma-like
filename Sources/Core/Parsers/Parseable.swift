protocol Parser {
    associatedtype Output

    mutating func parse(_ data: DataSource) -> ParseResult<Output>
}

protocol CodeReferenceConvertible: Equatable {
    var reference: CodeReference { get }
}

struct CodeReference {
    let message: String
    let line: Int
    let col: Int
}

enum ParseResult<S> {
    case withSuccess(result: S, warnings: [CodeReference])
    case withErrors(result: S?, warnings: [CodeReference], errors: [CodeReference])
}

extension ParseResult {
    var problems: [CodeReference] {
        switch self {
        case let .withErrors(_, warnings, errors):
            warnings + errors
        case let .withSuccess(_, warnings):
            warnings
        }
    }
}

extension ParseResult: Equatable where S: Equatable {
    static func == (lhs: ParseResult<S>, rhs: ParseResult<S>) -> Bool {
        switch (lhs, rhs) {
        case let (.withSuccess(result: r1, warnings: w1), .withSuccess(result: r2, warnings: w2)):
            r1 == r2 && w1 == w2
        case let (.withErrors(result: r1, warnings: w1, errors: e1), .withErrors(result: r2, warnings: w2, errors: e2)):
            e1 == e2 && r1 == r2 && w1 == w2
        default:
            false
        }
    }
}

extension CodeReference: Equatable {}
extension CodeReferenceConvertible {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reference == rhs.reference
    }
}
