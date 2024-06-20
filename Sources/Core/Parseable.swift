protocol Parser {
    associatedtype Output

    mutating func parse(_ data: DataSource) -> Output?
}
