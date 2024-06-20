extension String {
    func distanceToEnd(from pos: Index) -> Int {
        distance(from: pos, to: endIndex)
    }

    func take(from pos: Index, next count: Int) -> Substring {
        guard let next = index(pos, offsetBy: count, limitedBy: endIndex) else {
            return self[pos ..< endIndex]
        }
        return self[pos ..< next]
    }
}
