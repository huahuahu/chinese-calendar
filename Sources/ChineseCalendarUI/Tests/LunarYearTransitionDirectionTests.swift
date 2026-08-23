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
}
