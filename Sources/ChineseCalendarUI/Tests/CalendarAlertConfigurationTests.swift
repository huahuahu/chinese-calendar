import ChineseCalendarLocalization
@testable import ChineseCalendarUI
import Foundation
import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("业务配置配对结构化提示与独立动作")
struct CalendarAlertConfigurationTests {
    @Test(arguments: [false, true])
    func errorRoutesCarryTheirOwnRecoveryValue(isDownload: Bool) {
        let coordinator = CalendarHomeCoordinator()
        let failure = CalendarStoreFailure.server(status: 503)
        let route: CalendarAlert = isDownload
            ? .downloadFailed(failure: failure)
            : .clearDataFailed(failure: failure)
        #expect(configuration(coordinator).alert(
            for: route, presentation: coordinator.router.navigation.rootPresentation
        ) != nil)
        let message = CalendarStoreErrorPresentation.message(for: failure)
        let content = isDownload
            ? CalendarAlertContent.downloadFailed(message: message)
            : CalendarAlertContent.clearDataFailed(message: message)
        #expect(String(localized: content.message) == String(localized: message))
        #expect(content.buttons.map(\.action) == [.acknowledge])
        #expect(content.cancelButton == nil)
    }

    @Test func buildingClearConfigurationDoesNotStartTheStoreOperation() {
        let coordinator = CalendarHomeCoordinator()
        let store = ChineseCalendarStoreCoordinator(fullStoreConfiguration: nil)
        #expect(configuration(coordinator, store: store).alert(
            for: .clearDownloadedData, presentation: coordinator.router.navigation.rootPresentation
        ) != nil)
        #expect(!store.isClearingDownloadedData)
        guard case .starting = store.state else {
            Issue.record("构建提示不能触发 store 的清理或重建")
            return
        }
    }

    @Test func successfulClearAndNoticesHaveConfigurationsWithoutMessageRegistration() {
        let coordinator = CalendarHomeCoordinator()
        let config = configuration(coordinator)
        let context = coordinator.router.navigation.rootPresentation
        #expect(config.alert(for: .clearDataSucceeded, presentation: context) != nil)
        #expect(config.alert(for: .clearDataFailed(failure: .clear), presentation: context) != nil)
        #expect(config.alert(for: .downloadFailed(failure: .network), presentation: context) != nil)
        #if DEBUG
            #expect(config.alert(for: .debugNotice(1), presentation: context) != nil)
            #expect(config.alert(for: .debugNavigationChoice, presentation: context) != nil)
        #endif
    }

    private func configuration(
        _ coordinator: CalendarHomeCoordinator, store: ChineseCalendarStoreCoordinator? = nil
    ) -> CalendarNavigationConfiguration<EmptyView> {
        CalendarNavigationConfiguration(
            coordinator: coordinator, storeCoordinator: store,
            bottomStatusBarIsPresented: false, bottomStatusBar: { EmptyView() }
        )
    }
}
