@testable import ChineseCalendarUI
import NavigationCore
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("年份选择器使用真实导航宿主", .serialized)
struct CalendarYearPresentationTests {
    @Test func rejectedSubmissionReleasesItsSessionImmediately() throws {
        let router = NavigationTestHost.Router(rootDestination: .calendarHome)
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: container.mainContext)
        weak var rejectedSession: CalendarYearPickerSession?

        feature.presentYearPicker(presentation: router.rootPresentation) { session in
            rejectedSession = session
            return YearPickerTestConfiguration(feature: feature, session: session) { _ in }
        }

        #expect(feature.yearPickerSession == nil)
        #expect(rejectedSession == nil)
        #expect(feature.selection.selectedDayIndex == 315)
        #expect(feature.modelContext === container.mainContext)
    }

    @Test func acceptedDismissalRetainsSessionUntilPhysicalFinish() async throws {
        let router = NavigationTestHost.Router(rootDestination: .calendarHome)
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        let container = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: container.mainContext)
        var picker: CalendarPresentationContext?
        present(feature, from: router.rootPresentation) { picker = $0 }
        try await host.waitUntil { picker != nil }
        _ = try await host.waitForPresentation()
        let context = try #require(picker)
        let session = try #require(feature.yearPickerSession)

        present(feature, from: router.rootPresentation) { _ in Issue.record("重复呈现不能替换当前会话") }
        #expect(feature.yearPickerSession === session)
        #expect(context.dismiss().isAccepted)
        feature.selectYear(2025, session: session)
        #expect(feature.yearPickerSession === session)
        #expect(feature.pendingYearTransition?.destinationYearNumber == 2025)
        #expect(!context.dismiss().isAccepted)
        feature.selectYear(2027, session: session)
        #expect(feature.pendingYearTransition?.destinationYearNumber == 2025)

        try await host.waitUntil { feature.yearPickerSession == nil }
        feature.completeYearTransitionPreparation(3)
        #expect(feature.selection.selectedDayIndex == 201)
        #expect(!session.acceptsResult)
        await host.close()
    }

    @Test func nestedPickersReturnOnlyToTheirOwnPages() async throws {
        let router = NavigationTestHost.Router(rootDestination: .calendarHome)
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let first = makeFeature(context: firstContainer.mainContext)
        let second = makeFeature(context: secondContainer.mainContext)
        var firstPicker: CalendarPresentationContext?
        var secondPicker: CalendarPresentationContext?
        present(first, from: router.rootPresentation) { firstPicker = $0 }
        try await host.waitUntil { firstPicker != nil }
        _ = try await host.waitForPresentation()
        let firstContext = try #require(firstPicker)
        present(second, from: firstContext) { secondPicker = $0 }
        try await host.waitUntil { secondPicker != nil }
        _ = try await host.waitForPresentation()
        let secondContext = try #require(secondPicker)
        let secondSession = try #require(second.yearPickerSession)

        #expect(secondContext.dismiss().isAccepted)
        second.selectYear(2025, session: secondSession)
        second.completeYearTransitionPreparation(3)
        try await host.waitUntil { second.yearPickerSession == nil }

        #expect(second.selection.selectedDayIndex == 201)
        #expect(first.selection.selectedDayIndex == 315)
        #expect(first.yearPickerSession?.acceptsResult == true)
        #expect(first.yearPickerSession?.modelContext === firstContainer.mainContext)
        #expect(firstContext.dismiss().isAccepted)
        try await host.waitUntil { first.yearPickerSession == nil }
        await host.close()
    }

    @Test func replacingContextDismissesOnlyItsOwnPicker() async throws {
        let router = NavigationTestHost.Router(rootDestination: .calendarHome)
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        #expect(router.rootPresentation.present(.settings).result.isAccepted)
        let parent = try await host.context(for: .settings)
        let parentController = try await host.waitForPresentation()
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: firstContainer.mainContext)
        var picker: CalendarPresentationContext?
        present(feature, from: parent) { picker = $0 }
        try await host.waitUntil { picker != nil }
        _ = try await host.waitForPresentation()
        let oldSession = try #require(feature.yearPickerSession)

        feature.connect(modelContext: secondContainer.mainContext, storeCoordinator: nil)
        feature.selectYear(2025, session: oldSession)
        #expect(!oldSession.acceptsResult)
        #expect(feature.selection.selectedDayIndex == 315)
        try await host.waitUntil { feature.yearPickerSession == nil }

        #expect(host.presentedViewController() === parentController)
        #expect(feature.modelContext === secondContainer.mainContext)
        #expect(parent.dismiss().isAccepted)
        try await host.waitUntil { host.presentedViewController() == nil }
        await host.close()
    }

    @Test func invalidatingAQueuedPickerFinishesWithoutShowingIt() async throws {
        let router = NavigationTestHost.Router(rootDestination: .calendarHome)
        let host = try await NavigationTestHost.show(router: router)
        defer { host.removeFromWindow() }
        #expect(router.rootPresentation.presentAlert(.clearDataSucceeded).result == .applied)
        let alert = try await host.waitForAlert()
        let firstContainer = try PreviewSampleData.makeModelContainer()
        let secondContainer = try PreviewSampleData.makeModelContainer()
        let feature = makeFeature(context: firstContainer.mainContext)
        var appeared = false
        present(feature, from: router.rootPresentation) { _ in appeared = true }
        let session = try #require(feature.yearPickerSession)

        feature.connect(modelContext: secondContainer.mainContext, storeCoordinator: nil)

        #expect(feature.yearPickerSession == nil)
        #expect(!session.acceptsResult)
        #expect(!appeared)
        #expect(host.presentedViewController() === alert)
        #expect(feature.selection.selectedDayIndex == 315)
        await host.close()
    }

    private func makeFeature(context: ModelContext) -> CalendarYearFeature {
        let feature = CalendarYearFeature(selection: CalendarSelection(selectedDayIndex: 315))
        feature.connect(modelContext: context, storeCoordinator: nil)
        return feature
    }

    private func present(
        _ feature: CalendarYearFeature, from presentation: CalendarPresentationContext,
        record: @escaping @MainActor (CalendarPresentationContext) -> Void
    ) {
        feature.presentYearPicker(presentation: presentation) { session in
            YearPickerTestConfiguration(feature: feature, session: session, record: record)
        }
    }
}

private struct YearPickerTestConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = CalendarDestination
    typealias AlertRoute = CalendarAlert

    let feature: CalendarYearFeature
    let session: CalendarYearPickerSession
    let record: @MainActor (CalendarPresentationContext) -> Void

    func destination(for destination: CalendarDestination) -> some View {
        CalendarYearPickerDestinationView(feature: feature, session: session)
            .background(YearPickerContextRecorder(record: record))
    }
}

private struct YearPickerContextRecorder: View {
    let record: @MainActor (CalendarPresentationContext) -> Void
    @Environment(CalendarPresentationContext.self) private var presentation

    var body: some View {
        Color.clear.onAppear { record(presentation) }
    }
}
