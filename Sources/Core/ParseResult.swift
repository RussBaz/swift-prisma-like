enum ParseResult<S> {
    case withSuccess(result: S, messages: [any CodeReferencing])
    case withErrors(messages: [any CodeReferencing])
}

extension ParseResult: Equatable where S: Equatable {
    static func == (lhs: ParseResult<S>, rhs: ParseResult<S>) -> Bool {
        switch (lhs, rhs) {
        case let (.withSuccess(result: r1, messages: m1), .withSuccess(result: r2, messages: m2)):
            let same = zip(m1, m2).allSatisfy { a, b in a.isEqual(to: b) }
            return r1 == r2 && same
        case let (.withErrors(messages: m1), .withErrors(messages: m2)):
            let same = zip(m1, m2).allSatisfy { a, b in a.isEqual(to: b) }
            return same
        default:
            return false
        }
    }
}

extension ParseResult {
    var messages: [any CodeReferencing] {
        switch self {
        case let .withSuccess(_, messages): messages
        case let .withErrors(messages): messages
        }
    }
}
