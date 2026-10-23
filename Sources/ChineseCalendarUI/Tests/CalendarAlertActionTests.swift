@testable import ChineseCalendarUI
import Foundation
@testable import NavigationCore
import Testing

@MainActor
@Suite("各类提示动作的业务效果")
struct CalendarAlertActionTests {
    @Test func cancellingClearDoesNotRunTheOperationOrPresentAResult() async {
        let coordinator = CalendarHomeCoordinator()
        let context = coordinator.router.navigation.rootPresentation
        var clearCount = 0
        await coordinator.handleClearDownloadedDataAction(.cancel, presentation: context) {
            clearCount += 1
        }
        #expect(clearCount == 0)
        #expect(context.presentedAlert == nil)
        #expect(coordinator.alertMessages.isEmpty)
    }

    @Test func successfulClearQueuesItsResultUntilTheConfirmationFinishes() async throws {
        let coordinator = CalendarHomeCoordinator()
        let context = coordinator.router.navigation.rootPresentation
        context.presentAlert(.clearDownloadedData)
        let alert = try #require(context.presentedAlert)
        #expect(context.alertWillPresent(id: .business(alert.id)))
        context.alertWillDismiss(id: .business(alert.id))
        #expect(context.beginAlertCompletion(id: .business(alert.id)))
        var clearCount = 0
        await coordinator.handleClearDownloadedDataAction(.clear, presentation: context) {
            clearCount += 1
        }
        #expect(clearCount == 1)
        #expect(context.presentedAlert == nil)
        #expect(coordinator.router.navigation.alertRoutes == [.clearDataSucceeded])
        #expect(coordinator.alertMessages.isEmpty)
        context.alertDidDismiss(id: .business(alert.id))
        #expect(context.presentedAlert?.destination == .clearDataSucceeded)
    }

    @Test func failedClearKeepsItsMessageInTheOriginatingLayer() async throws {
        let coordinator = CalendarHomeCoordinator()
        let root = coordinator.router.navigation.rootPresentation
        root.present(.settings)
        let node = try #require(coordinator.router.sheet)
        let context = coordinator.router.navigation.presentationContext(for: node)
        await coordinator.handleClearDownloadedDataAction(.clear, presentation: context) {
            throw URLError(.notConnectedToInternet)
        }
        let route = try #require(context.presentedAlert?.destination)
        let messageID = try #require(route.messageID)
        #expect(route == .clearDataFailed(messageID: messageID))
        #expect(coordinator.alertMessages[messageID] != nil)
        #expect(root.presentedAlert == nil)
        coordinator.handleNoticeAction(.acknowledge, messageID: messageID)
        #expect(coordinator.alertMessages.isEmpty)
    }

    @Test func failedClearDoesNotLeakAMessageWhenItsLayerHasGoneAway() async throws {
        let coordinator = CalendarHomeCoordinator()
        let root = coordinator.router.navigation.rootPresentation
        root.present(.settings)
        let node = try #require(coordinator.router.sheet)
        let context = coordinator.router.navigation.presentationContext(for: node)
        await coordinator.handleClearDownloadedDataAction(.clear, presentation: context) {
            context.dismiss()
            root.presentationDidDismiss()
            throw URLError(.notConnectedToInternet)
        }
        #expect(!context.isActive)
        #expect(coordinator.alertMessages.isEmpty)
        #expect(coordinator.router.navigation.alertRoutes.isEmpty)
    }
}
