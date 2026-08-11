extension RandomAccessCollection {
    /// 在已按 `key` 升序排列的集合中查找目标值，避免对大型集合进行线性扫描。
    func binarySearchIndex<Key: Comparable>(
        of target: Key,
        by key: (Element) -> Key
    ) -> Index? {
        var lowerBound = startIndex
        var upperBound = endIndex

        while lowerBound < upperBound {
            let midpoint = index(
                lowerBound,
                offsetBy: distance(from: lowerBound, to: upperBound) / 2
            )

            if key(self[midpoint]) < target {
                lowerBound = index(after: midpoint)
            } else {
                upperBound = midpoint
            }
        }

        guard lowerBound != endIndex, key(self[lowerBound]) == target else {
            return nil
        }

        return lowerBound
    }
}
