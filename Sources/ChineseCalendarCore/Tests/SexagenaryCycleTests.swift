@testable import ChineseCalendarCore
import Testing

@Test func sexagenaryNameUsesCyclicStemAndBranchIndexes() {
    #expect(SexagenaryName(stemIndex: 0, branchIndex: 0).chineseName == "甲子")
    #expect(SexagenaryName(stemIndex: 9, branchIndex: 11).chineseName == "癸亥")
    #expect(SexagenaryName(stemIndex: 10, branchIndex: 12).chineseName == "甲子")
    #expect(SexagenaryName(stemIndex: -1, branchIndex: -1).chineseName == "癸亥")
}
