@testable import ChineseCalendarUI
import Foundation
@testable import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("业务配置配对具体提示内容与动作")
struct CalendarAlertConfigurationTests {
    @Test(arguments: [false, true])
    func acknowledgingAnErrorReleasesOnlyItsOwnMessage(isDownload: Bool) async throws {
        let coordinator = CalendarHomeCoordinator()
        let messageID = CalendarAlertMessageID()
        let otherID = CalendarAlertMessageID()
        coordinator.alertMessages[messageID] = "Displayed failure"
        coordinator.alertMessages[otherID] = "Unrelated failure"
        let route: CalendarAlert = isDownload
            ? .downloadFailed(messageID: messageID)
            : .clearDataFailed(messageID: messageID)
        let definition = try #require(configuration(coordinator).alert(
            for: route, presentation: coordinator.router.navigation.rootPresentation
        ))
        #expect(String(localized: definition.message) == "Displayed failure")
        #expect(definition.buttons.count == 1)
        #expect(!definition.buttons[0].isCancel)
        await definition.buttons[0].perform()
        #expect(coordinator.alertMessages[messageID] == nil)
        #expect(coordinator.alertMessages[otherID] != nil)
    }

    @Test func clearWithoutAStorePreservesTheExistingNoOpBehavior() async throws {
        let coordinator = CalendarHomeCoordinator()
        let context = coordinator.router.navigation.rootPresentation
        let definition = try #require(configuration(coordinator).alert(
            for: .clearDownloadedData,
            presentation: context
        ))
        #expect(definition.buttons.map(\.isCancel) == [true, false])
        #expect(definition.buttons.map(\.isDestructive) == [false, true])
        await definition.buttons[1].perform()
        #expect(context.presentedAlert == nil)
        #expect(coordinator.alertMessages.isEmpty)
    }

    @Test func clearCancellationDoesNotStartTheStoreOperation() async throws {
        let coordinator = CalendarHomeCoordinator()
        let store = ChineseCalendarStoreCoordinator(fullStoreConfiguration: nil)
        let definition = try #require(configuration(coordinator, store: store).alert(
            for: .clearDownloadedData, presentation: coordinator.router.navigation.rootPresentation
        ))
        await definition.buttons[0].perform()
        #expect(!store.isClearingDownloadedData)
        guard case .starting = store.state else {
            Issue.record("取消不能触发 store 的清理或重建")
            return
        }
        #expect(coordinator.router.navigation.alertRoutes.isEmpty)
    }

    #if DEBUG
        @Test func oneConfigurationHandlesNoticeAndNavigationWithDifferentActionTypes() async throws {
            let coordinator = CalendarHomeCoordinator()
            let config = configuration(coordinator)
            let context = coordinator.router.navigation.rootPresentation
            let notice = try #require(config.alert(for: .debugNotice(1), presentation: context))
            await notice.buttons[0].perform()
            #expect(coordinator.router.selectedTab == .years)
            #expect(coordinator.router.historyPath.isEmpty)
            let navigation = try #require(config.alert(for: .debugNavigationChoice, presentation: context))
            #expect(navigation.buttons.map(\.isCancel) == [true, false])
            await navigation.buttons[1].perform()
            #expect(coordinator.router.selectedTab == .history)
            #expect(coordinator.router.historyPath.count == 1)
            let destination = try #require(coordinator.router.historyPath.first)
            guard case .debugNavigation = destination else {
                Issue.record("导航选项必须把测试页压入历史栈")
                return
            }
        }

        @Test func cancellingDebugNavigationKeepsTheCurrentTabAndPath() async throws {
            let coordinator = CalendarHomeCoordinator()
            let definition = try #require(configuration(coordinator).alert(
                for: .debugNavigationChoice, presentation: coordinator.router.navigation.rootPresentation
            ))
            await definition.buttons[0].perform()
            #expect(coordinator.router.selectedTab == .years)
            #expect(coordinator.router.historyPath.isEmpty)
        }
    #endif

    private func configuration(
        _ coordinator: CalendarHomeCoordinator, store: ChineseCalendarStoreCoordinator? = nil
    ) -> CalendarNavigationConfiguration<EmptyView> {
        CalendarNavigationConfiguration(
            coordinator: coordinator, storeCoordinator: store,
            bottomStatusBarIsPresented: false, bottomStatusBar: { EmptyView() }
        )
    }
}
