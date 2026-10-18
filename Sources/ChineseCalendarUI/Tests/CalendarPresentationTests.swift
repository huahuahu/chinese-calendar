@testable import ChineseCalendarUI
import Foundation
import SwiftData
import Testing

@MainActor
@Suite("页面呈现上下文与协调")
struct CalendarPresentationTests {
    @Test func yearSelectionReturnsOnlyToItsOriginatingPage() throws {
        let coordinator = CalendarHomeCoordinator()
        let firstContainer = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let secondContainer = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let firstSelection = CalendarSelection(selectedDayIndex: 101)
        let secondSelection = CalendarSelection(selectedDayIndex: 202)

        coordinator.presentYearPicker(selection: firstSelection, modelContext: firstContainer.mainContext) {
            firstSelection.select(dayIndex: $0)
        }
        let parent = try #require(coordinator.router.sheet)
        let firstID = try sessionID(in: parent.destination)
        coordinator.presentYearPicker(selection: secondSelection, modelContext: secondContainer.mainContext) {
            secondSelection.select(dayIndex: $0)
        }
        let secondID = try sessionID(in: #require(parent.sheet).destination)

        #expect(coordinator.yearPickerSessions[firstID]?.selection === firstSelection)
        #expect(coordinator.yearPickerSessions[firstID]?.modelContext === firstContainer.mainContext)
        #expect(coordinator.yearPickerSessions[secondID]?.modelContext === secondContainer.mainContext)
        coordinator.selectYear(2027, sessionID: secondID)
        coordinator.selectYear(2028, sessionID: secondID)
        #expect(secondSelection.selectedDayIndex == 2027)
        #expect(firstSelection.selectedDayIndex == 101)
        #expect(coordinator.router.sheet === parent)
        #expect(parent.sheet == nil)

        coordinator.releaseDismissedContexts()
        #expect(coordinator.yearPickerSessions[secondID] == nil)
        coordinator.selectYear(2025, sessionID: firstID)
        #expect(firstSelection.selectedDayIndex == 2025)
        coordinator.rootPresentationDidDismiss()
        #expect(coordinator.yearPickerSessions.isEmpty)
    }

    @Test func cancelledYearPickerCannotDeliverAStaleResult() throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let selection = CalendarSelection(selectedDayIndex: 100)
        coordinator.presentYearPicker(selection: selection, modelContext: container.mainContext) {
            selection.select(dayIndex: $0)
        }
        let id = try sessionID(in: #require(coordinator.router.sheet).destination)

        // 模拟系统下滑对绑定的写回；动画结束前的旧回调也不能改变业务选择。
        coordinator.router.dismissSheet()
        coordinator.selectYear(2026, sessionID: id)
        #expect(selection.selectedDayIndex == 100)
        coordinator.rootPresentationDidDismiss()
        #expect(coordinator.yearPickerSessions.isEmpty)

        coordinator.presentYearPicker(selection: selection, modelContext: container.mainContext) { _ in }
        #expect(coordinator.router.sheet != nil)
    }

    @Test func repeatedYearPickerActionKeepsTheOriginalSession() throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let selection = CalendarSelection(selectedDayIndex: 100)
        coordinator.presentYearPicker(selection: selection, modelContext: container.mainContext) {
            selection.select(dayIndex: $0)
        }
        let original = try #require(coordinator.router.sheet)
        coordinator.presentYearPicker(selection: selection, modelContext: container.mainContext) { _ in
            Issue.record("重复打开不能替换原回调")
        }

        #expect(coordinator.router.presentations.count == 1)
        #expect(coordinator.yearPickerSessions.count == 1)
        try coordinator.selectYear(2026, sessionID: sessionID(in: original.destination))
        #expect(selection.selectedDayIndex == 2026)
    }

    @Test func storeChangeInvalidatesPickerButPreservesDownloadAndPaths() throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let selection = CalendarSelection(selectedDayIndex: 100)
        coordinator.storeIdentityDidChange("base")
        coordinator.router.push(.dynasty(orthodoxPeriodID: "ming"), on: .history)
        coordinator.presentDownloadDetails()
        let download = try #require(coordinator.router.sheet)
        coordinator.presentYearPicker(selection: selection, modelContext: container.mainContext) {
            selection.select(dayIndex: $0)
        }
        let id = try sessionID(in: #require(download.sheet).destination)

        coordinator.storeIdentityDidChange("full-v2")
        coordinator.selectYear(2026, sessionID: id)

        #expect(coordinator.yearPickerSessions.isEmpty)
        #expect(selection.selectedDayIndex == 100)
        #expect(download.sheet == nil)
        #expect(coordinator.router.sheet === download)
        #expect(coordinator.router.historyPath == [.dynasty(orthodoxPeriodID: "ming")])
        coordinator.downloadProgressDidDisappear()
        #expect(!coordinator.router.hasActivePresentation)
    }

    @Test func disappearingDownloadDoesNotDismissAnotherPresentation() throws {
        let coordinator = CalendarHomeCoordinator()
        coordinator.router.presentSheet(.lunarYear(2025))
        let parent = try #require(coordinator.router.sheet)
        coordinator.downloadProgressDidDisappear()
        #expect(coordinator.router.sheet === parent)

        coordinator.presentDownloadDetails()
        coordinator.presentDownloadDetails()
        #expect(coordinator.router.presentations.count == 2)
        coordinator.downloadProgressDidDisappear()
        #expect(coordinator.router.sheet === parent)
        #expect(parent.sheet == nil)
    }

    @Test func storeChangeDoesNotLoseLatestDeferredDeepLink() throws {
        let coordinator = CalendarHomeCoordinator()
        coordinator.storeIdentityDidChange("base")
        coordinator.presentDownloadDetails()
        coordinator.openDeepLink(.lunarYear(2025, monthIndex: nil))
        coordinator.storeIdentityDidChange("full")
        coordinator.openDeepLink(.emperor("ming-taizu"))
        let confirmation = try #require(coordinator.router.navigation.pendingConfirmation)
        coordinator.router.navigation.confirmNavigation(id: confirmation.id)
        coordinator.rootPresentationDidDismiss()

        #expect(coordinator.router.selectedTab == .history)
        #expect(coordinator.router.historyPath == [.emperor("ming-taizu")])
        #expect(coordinator.router.yearsPath.isEmpty)
    }

    @Test func rebuildingDataPagesDoesNotReplayColdLaunchLink() {
        let coordinator = CalendarHomeCoordinator()
        coordinator.openColdLaunchDeepLink(.lunarYear(2025, monthIndex: nil))
        coordinator.openDeepLink(.emperor("ming-taizu"))
        coordinator.storeIdentityDidChange("full")
        coordinator.openColdLaunchDeepLink(.lunarYear(2025, monthIndex: nil))
        #expect(coordinator.router.selectedTab == .history)
        #expect(coordinator.router.historyPath == [.emperor("ming-taizu")])
    }

    #if DEBUG
        @Test func previewDetailsShareFeatureStateAndRemainInTheSameTree() throws {
            let coordinator = CalendarHomeCoordinator()
            coordinator.presentDownloadPreview()
            let parent = try #require(coordinator.router.fullScreen)
            let session = try #require(coordinator.downloadPreviewSessions.values.first)
            coordinator.presentDownloadPreview()
            #expect(coordinator.router.presentations.count == 1)
            #expect(coordinator.downloadPreviewSessions.count == 1)
            session.stage = .downloading
            coordinator.presentDownloadPreviewDetails(sessionID: session.id)
            #expect(parent.sheet?.destination == .downloadPreviewDetails(sessionID: session.id))
            #expect(session.stage.progress.downloadFraction == 0.5)
            #expect(!parent.destination.usesPresentationNavigationStack)

            try coordinator.router.dismissPresentation(id: #require(parent.sheet).id)
            coordinator.releaseDismissedContexts()
            #expect(coordinator.downloadPreviewSessions[session.id] === session)
            coordinator.presentDownloadPreviewDetails(sessionID: session.id)
            coordinator.openDeepLink(.lunarYear(2026, monthIndex: nil))
            coordinator.openDeepLink(.emperor("ming-taizu"))
            let confirmation = try #require(coordinator.router.navigation.pendingConfirmation)
            #expect(coordinator.router.fullScreen === parent)
            coordinator.router.navigation.confirmNavigation(id: confirmation.id)
            #expect(coordinator.router.fullScreen == nil)
            #expect(coordinator.router.historyPath.isEmpty)
            coordinator.rootPresentationDidDismiss()
            #expect(coordinator.downloadPreviewSessions.isEmpty)
            #expect(coordinator.router.historyPath == [.emperor("ming-taizu")])

            coordinator.presentDownloadPreview()
            let reopened = try #require(coordinator.downloadPreviewSessions.values.first)
            #expect(reopened.id != session.id)
            #expect(reopened.stage == .preparing)
        }
    #endif

    private func sessionID(in destination: CalendarDestination) throws -> UUID {
        let id: UUID? = if case let .yearPicker(sessionID) = destination { sessionID } else { nil }
        return try #require(id)
    }
}
