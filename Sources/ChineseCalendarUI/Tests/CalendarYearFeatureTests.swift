import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import SwiftData
import Testing

@MainActor
@Suite("年份流程由发起日历页面持有")
struct CalendarYearFeatureTests {
    @Test func independentPagesKeepTheirOwnSelectionAndContext() throws {
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let first = makeFeature(context: firstContainer.mainContext, selectedDayIndex: 315)
        let second = makeFeature(context: secondContainer.mainContext, selectedDayIndex: 115)
        let firstSession = try #require(first.beginYearPicker())
        let secondSession = try #require(second.beginYearPicker())

        #expect(firstSession.selection === first.selection)
        #expect(secondSession.selection === second.selection)
        #expect(firstSession.modelContext === firstContainer.mainContext)
        #expect(secondSession.modelContext === secondContainer.mainContext)

        first.selectYear(2025, session: firstSession)
        first.completeYearTransitionPreparation(3)

        #expect(first.selection.selectedDayIndex == 201)
        #expect(second.selection.selectedDayIndex == 115)
        #expect(second.pendingYearTransition == nil)
        #expect(secondSession.acceptsResult)
    }

    @Test func oneResultKeepsBoundaryMonthTransitionUntilPreparationCompletes() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: container.mainContext, selectedDayIndex: 315)
        let session = try #require(feature.beginYearPicker())

        feature.selectYear(2025, session: session)
        feature.selectYear(2027, session: session)

        #expect(feature.selection.selectedDayIndex == 315)
        #expect(feature.pendingYearTransition?.sourceMonthIndex == 3)
        #expect(feature.pendingYearTransition?.destinationMonthIndex == 2)
        #expect(feature.pendingYearTransition?.destinationYearNumber == 2025)
        #expect(!session.acceptsResult)

        feature.completeYearTransitionPreparation(5)
        #expect(feature.selection.selectedDayIndex == 315)
        feature.completeYearTransitionPreparation(3)
        #expect(feature.selection.selectedDayIndex == 201)
        #expect(feature.pendingYearTransition == nil)
    }

    @Test func repeatedOpeningWaitsForTheCurrentRequestToFinish() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: container.mainContext, selectedDayIndex: 315)
        let first = try #require(feature.beginYearPicker())

        #expect(feature.beginYearPicker() == nil)
        feature.selectYear(2025, session: first)
        #expect(feature.beginYearPicker() == nil)

        feature.finishYearPicker(session: first)
        let second = try #require(feature.beginYearPicker())
        #expect(second !== first)
        feature.finishYearPicker(session: first)
        #expect(feature.yearPickerSession === second)
        #expect(second.acceptsResult)
    }

    @Test func replacedContextInvalidatesResultsAndPendingTransition() throws {
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: firstContainer.mainContext, selectedDayIndex: 315)
        let oldSession = try #require(feature.beginYearPicker())
        feature.selectYear(2025, session: oldSession)

        feature.connect(modelContext: secondContainer.mainContext, storeCoordinator: nil)
        feature.selectYear(2027, session: oldSession)
        feature.completeYearTransitionPreparation(3)

        #expect(feature.selection.selectedDayIndex == 315)
        #expect(feature.pendingYearTransition == nil)
        #expect(!oldSession.acceptsResult)
        #expect(feature.yearPickerSession === oldSession)
        feature.finishYearPicker(session: oldSession)
        let newSession = try #require(feature.beginYearPicker())
        #expect(newSession.modelContext === secondContainer.mainContext)
        #expect(newSession.storeGeneration != oldSession.storeGeneration)
    }

    @Test func cancelledSessionCannotChangeSelectionOrClearAReplacement() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: container.mainContext, selectedDayIndex: 315)
        let cancelled = try #require(feature.beginYearPicker())
        feature.finishYearPicker(session: cancelled)
        let replacement = try #require(feature.beginYearPicker())

        feature.selectYear(2025, session: cancelled)
        feature.finishYearPicker(session: cancelled)

        #expect(feature.selection.selectedDayIndex == 315)
        #expect(feature.pendingYearTransition == nil)
        #expect(feature.yearPickerSession === replacement)
    }

    @Test func finishingReleasesOnlyThePickerResources() throws {
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: container.mainContext, selectedDayIndex: 315)
        weak var releasedSession: CalendarYearPickerSession?
        do {
            let session = try #require(feature.beginYearPicker())
            releasedSession = session
            feature.finishYearPicker(session: session)
        }

        #expect(releasedSession == nil)
        #expect(feature.selection.selectedDayIndex == 315)
        #expect(feature.modelContext === container.mainContext)
    }

    @Test func retainedSessionDoesNotKeepItsOriginatingFeatureAlive() throws {
        let container = try PreviewSampleData.makeModelContainer()
        weak var releasedFeature: CalendarYearFeature?
        let session: CalendarYearPickerSession
        do {
            let feature = makeFeature(context: container.mainContext, selectedDayIndex: 315)
            releasedFeature = feature
            session = try #require(feature.beginYearPicker())
        }

        #expect(releasedFeature == nil)
        #expect(session.selection.selectedDayIndex == 315)
    }

    private func makeFeature(context: ModelContext, selectedDayIndex: Int) -> CalendarYearFeature {
        let feature = CalendarYearFeature(selection: CalendarSelection(selectedDayIndex: selectedDayIndex))
        feature.connect(modelContext: context, storeCoordinator: nil)
        return feature
    }
}
