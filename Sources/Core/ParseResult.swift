enum ParseResult<S> {
    case withSuccess(result: S, warnings: [CodeReference])
    case withErrors(warnings: [CodeReference], errors: [CodeReference])
}

extension ParseResult {
    var problems: [CodeReference] {
        switch self {
        case let .withErrors(warnings, errors):
            warnings + errors
        case let .withSuccess(_, warnings):
            warnings
        }
    }

    var warnings: [CodeReference] {
        switch self {
        case let .withErrors(warnings, _):
            warnings
        case let .withSuccess(_, warnings):
            warnings
        }
    }

    var errors: [CodeReference] {
        switch self {
        case let .withErrors(_, errors):
            errors
        case .withSuccess:
            []
        }
    }
}

extension ParseResult: Equatable where S: Equatable {
    static func == (lhs: ParseResult<S>, rhs: ParseResult<S>) -> Bool {
        switch (lhs, rhs) {
        case let (.withSuccess(result: r1, warnings: w1), .withSuccess(result: r2, warnings: w2)):
            r1 == r2 && w1 == w2
        case let (.withErrors(warnings: w1, errors: e1), .withErrors(warnings: w2, errors: e2)):
            e1 == e2 && w1 == w2
        default:
            false
        }
    }
}
