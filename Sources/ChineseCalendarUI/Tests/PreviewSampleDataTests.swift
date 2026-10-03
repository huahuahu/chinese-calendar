import ChineseCalendarCore
import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("Calendar preview fixtures")
struct PreviewSampleDataTests {
    @Test func historicalMonthsHaveCompleteStableRelationships() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let months = try container.mainContext.fetch(FetchDescriptor<ChineseLunarMonth>())
            .filter { $0.lunarMonthIndex < 0 }

        #expect(months.count == 19)
        for month in months {
            let days = month.days.sorted { $0.dayNumberInMonth < $1.dayNumberInMonth }
            #expect(days.count == month.dayCount)
            #expect(month.chineseLunarYear != nil)
            #expect(days.map(\.dayNumberInMonth) == Array(1 ... month.dayCount))
            for day in days {
                #expect(day.dayIndex == month.lunarMonthIndex * 100 + day.dayNumberInMonth)
                #expect(day.chineseLunarMonth?.lunarMonthIndex == month.lunarMonthIndex)
                #expect(day.calendarDay?.chineseLunarDay?.dayIndex == day.dayIndex)
                #expect((0 ..< 10).contains(day.dayStemIndex))
                #expect((0 ..< 12).contains(day.dayBranchIndex))
            }
        }
    }

    @Test func eraBoundaryResolvesBothDirectionsWithoutADisplayedYearZero() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let resolver = CalendarSelectionResolver(modelContext: container.mainContext)
        let beforeIndex = try #require(try resolver.monthIndex(forDayIndex: PreviewCalendarScenario.beforeCommonEra
                .selectedDayIndex))
        let afterIndex = try #require(try resolver
            .monthIndex(forDayIndex: PreviewCalendarScenario.commonEra.selectedDayIndex))
        let nextMonth = try #require(try resolver.adjacentMonth(to: beforeIndex, direction: .later))
        let previousMonth = try #require(try resolver.adjacentMonth(to: afterIndex, direction: .earlier))

        #expect(nextMonth.lunarMonthIndex == afterIndex)
        #expect(previousMonth.lunarMonthIndex == beforeIndex)
        #expect(try LunarCalendarFormatting
            .yearTitle(lunarYearNumber: #require(previousMonth.chineseLunarYear).lunarYearNumber) == "公元前 1 年")
        #expect(try LunarCalendarFormatting
            .yearTitle(lunarYearNumber: #require(nextMonth.chineseLunarYear).lunarYearNumber) == "公元 1 年")
        let previousJulianDays = previousMonth.days.compactMap { $0.calendarDay?.julianDayNumber }
        let nextJulianDays = nextMonth.days.compactMap { $0.calendarDay?.julianDayNumber }
        let lastJulianDay = try #require(previousJulianDays.max())
        let firstJulianDay = try #require(nextJulianDays.min())
        #expect(firstJulianDay == lastJulianDay + 1)
        #expect(try resolver.selectedDayIndex(
            inBoundaryMonthOf: 1,
            direction: .later,
            todayJulianDayNumber: 0
        ) == PreviewCalendarScenario.commonEra
            .selectedDayIndex)
        let reverseDay = try resolver.selectedDayIndex(
            inBoundaryMonthOf: 0,
            direction: .earlier,
            todayJulianDayNumber: 0
        )
        #expect(try resolver.monthIndex(forDayIndex: reverseDay) == beforeIndex)
    }

    @Test func postNinthMonthRetainsNameIdentityAndAncientYearBoundary() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let resolver = CalendarSelectionResolver(modelContext: container.mainContext)
        let index = try #require(try resolver
            .monthIndex(forDayIndex: PreviewCalendarScenario.postNinthMonth.selectedDayIndex))
        let previous = try #require(try resolver.adjacentMonth(to: index, direction: .earlier))
        let post = try #require(try resolver.adjacentMonth(to: previous.lunarMonthIndex, direction: .later))
        let next = try #require(try resolver.adjacentMonth(to: index, direction: .later))

        #expect(LunarMonthDisplay.title(for: previous) == "九月大")
        #expect(LunarMonthDisplay.title(for: post) == "后九月小")
        #expect(previous.monthNumberInYear == post.monthNumberInYear)
        #expect(previous.lunarMonthIndex != post.lunarMonthIndex)
        #expect(post.intercalaryMonthNameStyle == .post)
        #expect(next.monthNumberInYear == 10)
        #expect(try #require(next.chineseLunarYear).lunarYearNumber == #require(post.chineseLunarYear)
            .lunarYearNumber + 1)
        #expect(LunarCalendarFormatting.monthTitle(
            monthNumberInYear: 6,
            isLeapMonth: true,
            intercalaryMonthNameStyle: .post
        ) == "后六月")
    }

    @Test func civilEraBoundaryIsInsideALunarMonth() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let days = try container.mainContext.fetch(FetchDescriptor<ChineseLunarDay>())
        let selectedDay = try #require(days.first { $0.dayIndex == PreviewCalendarScenario.civilEraBoundary
                .selectedDayIndex
        })
        let month = try #require(selectedDay.chineseLunarMonth)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let eras = month.days.compactMap { day -> Int? in
            guard let julianDay = day.calendarDay?.julianDayNumber else { return nil }
            return calendar.component(.era, from: JulianDayNumber.dateAtNoonUTC(for: julianDay))
        }
        #expect(Set(eras) == [0, 1])
        #expect(month.chineseLunarYear?.lunarYearNumber == 0)
        #expect(month.monthNumberInYear == 11)
    }

    @Test func emptyAndModernScenariosRemainAvailable() throws {
        let empty = try PreviewSampleData.makeContext(includesSampleData: false)
        #expect(empty.selectedDayIndex == nil)
        #expect(try empty.modelContainer.mainContext.fetchCount(FetchDescriptor<ChineseLunarYear>()) == 0)
        let sample = try PreviewSampleData.makeContext(includesSampleData: true)
        let resolver = CalendarSelectionResolver(modelContext: sample.modelContainer.mainContext)
        #expect(sample.selectedDayIndex == PreviewCalendarScenario.modern.selectedDayIndex)
        #expect(try resolver.yearNumber(forDayIndex: sample.selectedDayIndex) == 2026)
        #expect(try resolver.contains(dayIndex: -1) == false)
    }
}
