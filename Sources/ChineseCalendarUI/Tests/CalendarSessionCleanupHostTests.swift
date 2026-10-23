@testable import ChineseCalendarUI
@testable import NavigationCore
import Observation
import SwiftData
import SwiftUI
import Testing
import UIKit

@MainActor
@Suite("根宿主自动清理业务会话")
struct CalendarSessionCleanupHostTests {
    @Test(.timeLimit(.minutes(1)))
    func hostReleasesSessionsAfterCompletionWithoutAConfigurationCallback() async throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        coordinator.presentYearPicker(
            selection: CalendarSelection(selectedDayIndex: 0), modelContext: container.mainContext
        ) { _ in }
        let window = await showCleanupHost(coordinator)
        defer { window.isHidden = true }
        #expect(coordinator.yearPickerSessions.count == 1)
        coordinator.router.dismissSheet()
        #expect(coordinator.yearPickerSessions.count == 1)
        coordinator.router.navigation.rootPresentation.presentationDidDismiss()
        await waitForPickerCleanup(coordinator)
        #expect(coordinator.yearPickerSessions.isEmpty)
    }

    @Test(.timeLimit(.minutes(1)))
    func hostCleansQueueDiscardedBeforeItsNextUpdate() async throws {
        let coordinator = CalendarHomeCoordinator()
        let container = try PreviewSampleData.makeModelContainer(includesSampleData: false)
        let window = await showCleanupHost(coordinator)
        defer { window.isHidden = true }
        let root = coordinator.router.navigation.rootPresentation
        root.presentAlert(.clearDataSucceeded)
        let alert = try #require(root.presentedAlert)
        #expect(root.alertWillPresent(id: .business(alert.id)))
        coordinator.presentYearPicker(
            selection: CalendarSelection(selectedDayIndex: 0), modelContext: container.mainContext
        ) { _ in }
        coordinator.router.navigation.dismissAllPresentations()
        root.alertWillDismiss(id: .business(alert.id))
        #expect(root.beginAlertCompletion(id: .business(alert.id)))
        root.alertDidDismiss(id: .business(alert.id))
        #expect(coordinator.router.navigation.retainedPresentationRoutes.isEmpty)
        #expect(coordinator.yearPickerSessions.count == 1)
        await waitForPickerCleanup(coordinator)
        #expect(coordinator.yearPickerSessions.isEmpty)
    }

    private func showCleanupHost(_ coordinator: CalendarHomeCoordinator) async -> UIWindow {
        // SwiftPM 的测试进程没有 App scene，使用仅供本测试的窗口驱动 SwiftUI 更新。
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let (appearances, continuation) = AsyncStream.makeStream(of: Void.self)
        window.rootViewController = UIHostingController(rootView: Color.clear
            .modifier(CalendarNavigationSessionCleanup(coordinator: coordinator))
            .onAppear {
                continuation.yield(())
                continuation.finish()
            })
        window.isHidden = false
        var iterator = appearances.makeAsyncIterator()
        _ = await iterator.next()
        return window
    }

    private func waitForPickerCleanup(_ coordinator: CalendarHomeCoordinator) async {
        for await isEmpty in Observations({ coordinator.yearPickerSessions.isEmpty }) where isEmpty {
            return
        }
    }
}
