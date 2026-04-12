@testable import ChineseCalendarData
import Foundation
import Testing

@Test func placeholderRepositoryPreservesRequestedGregorianDate() async throws {
    let repository = PlaceholderCalendarDataRepository()
    let requestedDate = Date(timeIntervalSince1970: 123_456)

    let result = try await repository.calendarDate(for: requestedDate)

    #expect(result != nil)
    #expect(result?.gregorianDate == requestedDate)
}

@Test func placeholderRepositoryReturnsStablePlaceholderLunarDate() async throws {
    let repository = PlaceholderCalendarDataRepository()

    let result = try await repository.calendarDate(for: Date(timeIntervalSince1970: 0))

    #expect(result?.lunarYear == 2026)
    #expect(result?.lunarMonth == 1)
    #expect(result?.lunarDay == 1)
    #expect(result?.isLeapMonth == false)
}
