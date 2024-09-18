protocol CodeReferencing: Equatable {
    associatedtype T: ParseMessage

    var message: T { get }
    var line: Int { get }
    var col: Int { get }
    var level: MessageLevel { get }

    func isEqual(to value: any CodeReferencing) -> Bool
}

public struct CodeReference<T: ParseMessage>: CodeReferencing {
    func isEqual(to value: any CodeReferencing) -> Bool {
        guard let value = value as? CodeReference<T> else { return false }
        return self == value
    }

    let message: T
    let line: Int
    let col: Int
    let level: MessageLevel
}

enum MessageLevel: Equatable {
    case warning
    case error
}

extension [any CodeReferencing] {
    static func + (lhs: [any CodeReferencing], rhs: any CodeReferencing) -> [any CodeReferencing] {
        lhs + [rhs]
    }

    static func + (lhs: any CodeReferencing, rhs: [any CodeReferencing]) -> [any CodeReferencing] {
        [lhs] + rhs
    }
}
