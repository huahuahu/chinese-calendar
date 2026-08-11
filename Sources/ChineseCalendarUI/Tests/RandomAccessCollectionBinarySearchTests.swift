@testable import ChineseCalendarUI
import Testing

@Test func binarySearchFindsFirstMiddleAndLastElements() {
    let values = [10, 20, 30, 40, 50]

    #expect(values.binarySearchIndex(of: 10, by: { $0 }) == 0)
    #expect(values.binarySearchIndex(of: 30, by: { $0 }) == 2)
    #expect(values.binarySearchIndex(of: 50, by: { $0 }) == 4)
}

@Test func binarySearchReturnsNilForMissingElementsAndEmptyCollections() {
    let values = [10, 20, 30, 40, 50]
    let empty: [Int] = []

    #expect(values.binarySearchIndex(of: 5, by: { $0 }) == nil)
    #expect(values.binarySearchIndex(of: 35, by: { $0 }) == nil)
    #expect(values.binarySearchIndex(of: 60, by: { $0 }) == nil)
    #expect(empty.binarySearchIndex(of: 10, by: { $0 }) == nil)
}
