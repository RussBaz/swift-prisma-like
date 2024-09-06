protocol CodeReferenceConvertible: Equatable {
    var reference: CodeReference { get }
}

extension CodeReferenceConvertible {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.reference == rhs.reference
    }
}
