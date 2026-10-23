import ChineseCalendarLocalization
@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("各类提示动作的业务效果", .serialized)
struct CalendarAlertActionTests {
    @Test func cancellingClearDoesNotRunTheOperationOrPresentAResult() async throws {
        let coordinator = CalendarHomeCoordinator()
        let context = coordinator.router.navigation.rootPresentation
        let host = try await alertHost(coordinator)
        defer { host.removeFromWindow() }
        var clearCount = 0
        await coordinator.handleClearDownloadedDataAction(.cancel, presentation: context) {
            clearCount += 1
        }
        #expect(clearCount == 0)
        #expect(context.present(.settings).result == .applied)
        await host.close()
    }

    @Test func successfulClearPresentsAResultBeforeTheNextPage() async throws {
        let coordinator = CalendarHomeCoordinator()
        let context = coordinator.router.navigation.rootPresentation
        let host = try await alertHost(coordinator)
        defer { host.removeFromWindow() }
        var clearCount = 0
        await coordinator.handleClearDownloadedDataAction(.clear, presentation: context) {
            clearCount += 1
        }
        #expect(clearCount == 1)
        // 结果提示占用本层；后续页面按照公开呈现合同进入队列。
        let alert = try await host.waitForAlert()
        #expect(alert.actions.count == 1)
        #expect(alert.message == String(localized: CalendarStringKey.Settings.ClearData.successMessage))
        #expect(context.present(.settings).result == .queued)
        await host.close()
    }

    @Test func failedClearPresentsRecoveryWithoutRetainingTheError() async throws {
        let coordinator = CalendarHomeCoordinator()
        let context = coordinator.router.navigation.rootPresentation
        let host = try await alertHost(coordinator)
        defer { host.removeFromWindow() }
        await coordinator.handleClearDownloadedDataAction(.clear, presentation: context) {
            throw URLError(.notConnectedToInternet)
        }
        let alert = try await host.waitForAlert()
        #expect(alert.actions.count == 1)
        #expect(alert.message == String(localized: CalendarStoreErrorPresentation.message(for: .network)))
        #expect(context.present(.settings).result == .queued)
        await host.close()
    }

    @Test func clearWithoutAStoreDoesNotPresentAResult() async throws {
        let coordinator = CalendarHomeCoordinator()
        let context = coordinator.router.navigation.rootPresentation
        let host = try await alertHost(coordinator)
        defer { host.removeFromWindow() }
        await coordinator.handleClearDownloadedDataAction(.clear, presentation: context, clearDownloadedData: nil)
        #expect(context.present(.settings).result == .applied)
        await host.close()
    }

    @Test func failureAfterTheNavigationOwnerEndsCannotPresentAnotherAlert() async throws {
        let coordinator = CalendarHomeCoordinator()
        var router: NavigationRouter<CalendarTab, CalendarDestination, CalendarAlert>? =
            .init(rootDestination: .settings)
        let context = try #require(router).rootPresentation
        await coordinator.handleClearDownloadedDataAction(.clear, presentation: context) {
            router = nil
            throw URLError(.notConnectedToInternet)
        }
        #expect(context.presentAlert(.clearDataSucceeded).result == .rejected(.inactiveContext))
    }

    private func alertHost(_ coordinator: CalendarHomeCoordinator) async throws -> NavigationTestHost {
        let configuration = CalendarNavigationConfiguration(
            coordinator: coordinator, storeCoordinator: nil,
            bottomStatusBarIsPresented: { false }, bottomStatusBar: { EmptyView() }
        )
        return try await NavigationTestHost.show(Color.clear.navigationHost(
            context: coordinator.router.navigation.rootPresentation, configuration: configuration
        ))
    }

    #if DEBUG
        @Test func debugActionsRetainTheirIndependentNavigationBehavior() {
            let coordinator = CalendarHomeCoordinator()
            let context = coordinator.router.navigation.rootPresentation
            let history = context.context(for: .scope(.history))
            coordinator.handleDebugNavigationAction(.cancel)
            #expect(context.selectedStack == .scope(.years))
            #expect(history.path.isEmpty)
            coordinator.handleDebugNavigationAction(.openHistory)
            #expect(context.selectedStack == .scope(.history))
            #expect(history.path.count == 1)
            guard case .debugNavigation = history.path.first else {
                Issue.record("导航选项必须把测试页压入历史栈")
                return
            }
        }
    #endif
}
