@testable import ChineseCalendarUI
import Testing

@Suite("Lunar year transition direction")
struct LunarYearTransitionDirectionTests {
    @Test func laterYearMovesForwardAlongTheTimeline() {
        #expect(LunarYearTransitionDirection(from: 2026, to: 2030) == .later)
    }

    @Test func earlierYearMovesBackwardAlongTheTimeline() {
        #expect(LunarYearTransitionDirection(from: 2026, to: 1800) == .earlier)
    }

    @Test func equalYearHasNoTransition() {
        #expect(LunarYearTransitionDirection(from: 2026, to: 2026) == nil)
    }

    @Test func directionRemainsChronologicalAcrossCommonEraBoundary() {
        #expect(LunarYearTransitionDirection(from: -1, to: 1) == .later)
        #expect(LunarYearTransitionDirection(from: 1, to: -1) == .earlier)
    }

    @Test func laterYearLeavesFromTheCurrentYearsLastMonth() {
        let direction = LunarYearTransitionDirection.later

        #expect(direction.sourceMonthIndex(in: [26001, 26002, 26012]) == 26012)
    }

    @Test func earlierYearLeavesFromTheCurrentYearsFirstMonth() {
        let direction = LunarYearTransitionDirection.earlier

        #expect(direction.sourceMonthIndex(in: [26001, 26002, 26012]) == 26001)
    }

    @Test func laterYearStartsAtItsFirstMonth() {
        let direction = LunarYearTransitionDirection.later

        #expect(direction.destinationMonthIndex(in: [26001, 26002, 26012]) == 26001)
    }

    @Test func earlierYearStartsAtItsLastMonth() {
        let direction = LunarYearTransitionDirection.earlier

        #expect(direction.destinationMonthIndex(in: [26001, 26002, 26012]) == 26012)
    }

    @Test func aYearWithoutMonthsHasNoDestinationMonth() {
        #expect(LunarYearTransitionDirection.later.destinationMonthIndex(in: []) == nil)
        #expect(LunarYearTransitionDirection.earlier.destinationMonthIndex(in: []) == nil)
    }

    @Test func aYearWithoutMonthsHasNoSourceMonth() {
        #expect(LunarYearTransitionDirection.later.sourceMonthIndex(in: []) == nil)
        #expect(LunarYearTransitionDirection.earlier.sourceMonthIndex(in: []) == nil)
    }
}
