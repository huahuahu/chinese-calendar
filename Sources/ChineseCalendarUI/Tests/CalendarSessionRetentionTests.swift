@testable import ChineseCalendarUI
import Foundation
@testable import NavigationCore
import SwiftData
import Testing

@MainActor
@Suite("业务会话按呈现身份释放")
struct CalendarSessionRetentionTests {
    @Test func registrationSnapshotIncludesEachBusinessIdentityCategory() throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        coordinator.presentYearPicker(
            selection: CalendarSelection(selectedDayIndex: 0), modelContext: container.mainContext
        ) { _ in }
        let pickerID = try #require(coordinator.yearPickerSessions.keys.first)
        #expect(coordinator.presentDownloadError("Test download error"))
        let messageID = try #require(coordinator.alertMessages.keys.first)
        var expected: Set<CalendarPresentationSessionID> = [.yearPicker(pickerID), .alertMessage(messageID)]
        #expect(coordinator.presentationSessionIDs == expected)
        #if DEBUG
            coordinator.presentDownloadPreview()
            let previewID = try #require(coordinator.downloadPreviewSessions.keys.first)
            expected.insert(.downloadPreview(previewID))
            #expect(coordinator.presentationSessionIDs == expected)
        #endif
    }

    @Test func ancestorCompletionReleasesPickersButKeepsSessionsDuringAnimation() throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        for index in 0 ..< 2 {
            coordinator.presentYearPicker(
                selection: CalendarSelection(selectedDayIndex: index), modelContext: container.mainContext
            ) { _ in }
        }
        #expect(coordinator.yearPickerSessions.count == 2)
        coordinator.router.dismissSheet()
        coordinator.releaseDismissedContexts()
        #expect(coordinator.yearPickerSessions.count == 2)
        coordinator.router.navigation.rootPresentation.presentationDidDismiss()
        coordinator.releaseDismissedContexts()
        #expect(coordinator.yearPickerSessions.isEmpty)
    }

    @Test func queuedPickerIsKeptUntilTheQueueIsDiscarded() throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let root = coordinator.router.navigation.rootPresentation
        root.presentAlert(.clearDataSucceeded)
        let alert = try #require(root.presentedAlert)
        #expect(root.alertWillPresent(id: .business(alert.id)))
        coordinator.presentYearPicker(
            selection: CalendarSelection(selectedDayIndex: 0), modelContext: container.mainContext
        ) { _ in }
        coordinator.releaseDismissedContexts()
        #expect(coordinator.yearPickerSessions.count == 1)
        #expect(coordinator.router.sheet == nil)
        coordinator.router.navigation.dismissAllPresentations()
        root.alertWillDismiss(id: .business(alert.id))
        #expect(root.beginAlertCompletion(id: .business(alert.id)))
        root.alertDidDismiss(id: .business(alert.id))
        coordinator.releaseDismissedContexts()
        #expect(coordinator.yearPickerSessions.isEmpty)
    }

    @Test func rejectedPickerDoesNotLeaveABusinessSession() throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        coordinator.router.presentSheet(.calendarHome)
        let parent = try #require(coordinator.router.sheet)
        let context = coordinator.router.navigation.presentationContext(for: parent)
        context.present(.settings)
        try context.dismissPresented(id: #require(parent.presentation).id)
        // 默认入口此时是仍在等待子页关闭的父层；拒绝后不得留下刚创建的年份会话。
        coordinator.presentYearPicker(
            selection: CalendarSelection(selectedDayIndex: 0), modelContext: container.mainContext
        ) { _ in }
        #expect(coordinator.yearPickerSessions.isEmpty)
    }

    #if DEBUG
        @Test func cleanupDuringNestedDismissalKeepsSplitStateUntilAncestorCompletes() throws {
            let coordinator = CalendarHomeCoordinator()
            let root = coordinator.router.navigation.rootPresentation
            root.presentDebugSplit(layout: .twoColumn)
            let parent = try #require(coordinator.router.sheet)
            let context = coordinator.router.navigation.presentationContext(for: parent)
            let navigation = context.context(for: .primary)
            weak var state = coordinator.debugSplitState(for: navigation)
            coordinator.presentDownloadPreview(presentation: context)
            #expect(coordinator.downloadPreviewSessions.count == 1)
            context.dismiss()
            coordinator.releaseDismissedContexts()
            #expect(state != nil)
            #expect(coordinator.downloadPreviewSessions.count == 1)
            context.presentationDidDismiss()
            coordinator.releaseDismissedContexts()
            #expect(state != nil)
            #expect(coordinator.downloadPreviewSessions.count == 1)
            root.presentationDidDismiss()
            coordinator.releaseDismissedContexts()
            #expect(state == nil)
            #expect(coordinator.downloadPreviewSessions.isEmpty)
        }
    #endif
}
