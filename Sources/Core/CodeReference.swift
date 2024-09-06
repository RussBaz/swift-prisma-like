struct CodeReference {
    let message: String
    let line: Int
    let col: Int
}

extension CodeReference: Equatable {}
