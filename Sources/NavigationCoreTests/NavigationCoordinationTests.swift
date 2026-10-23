import Foundation
@testable import NavigationCore
import Testing

// swiftformat:disable:next modifierOrder
nonisolated private enum CoordinationNotice: NavigationAlertRoute {
    case message
}

@MainActor
@Suite("导航请求协调状态")
struct NavigationCoordinationTests {
    private enum Tab: NavigationScope { case home, history }
    private enum Route: NavigationDestination {
        case root, first, second, third
        var providesNavigationContainer: Bool {
            self == .root
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, CoordinationNotice>
    private typealias Presentation = NavigationPresentationContext<Tab, Route, CoordinationNotice>

    @Test(arguments: [true, false], [true, false])
    func pendingRequestResolvesIndependentlyOfAcceptedRequest(
        approve: Bool, resolveBeforeDismissal: Bool
    ) throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        router.presentSheet(.first)
        #expect(router.submit(.push(.second, on: .history)) == .deferredUntilPresentationDismisses)
        #expect(router.submit(.push(.third, on: .history), confirmIfPresented: true) == .awaitingConfirmation)
        let confirmation = try #require(router.pendingConfirmation)
        #expect(router.deferredRequest == .push(.second, on: .history))
        #expect(router.path(for: .history).isEmpty)

        if resolveBeforeDismissal {
            resolve(confirmation.id, on: router, approve: approve)
            #expect(router.pendingConfirmation == nil)
            #expect(router.deferredRequest == .push(approve ? .third : .second, on: .history))
            #expect(router.path(for: .history).isEmpty)
        }
        router.rootPresentation.presentationDidDismiss()
        if !resolveBeforeDismissal {
            #expect(router.pendingConfirmation?.id == confirmation.id)
            #expect(router.path(for: .history) == [.second])
            resolve(confirmation.id, on: router, approve: approve)
        }

        let expected: [Route] = approve ? (resolveBeforeDismissal ? [.third] : [.second, .third]) : [.second]
        #expect(router.path(for: .history) == expected)
        #expect(router.pendingConfirmation == nil)
        #expect(router.deferredRequest == nil)
        router.confirmNavigation(id: confirmation.id)
        router.cancelConfirmation(id: confirmation.id)
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == expected)
    }

    @Test(arguments: [true, false], [true, false])
    func alertReplacementKeepsLatestRequestAndPolicy(
        firstRequiresConfirmation: Bool, latestRequiresConfirmation: Bool
    ) throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        router.presentSheet(.first)
        let page = try #require(router.sheet)
        let context = router.presentationContext(for: page)
        let alertID = try beginAlert(context)
        #expect(router.submit(
            .push(.second, on: .history), confirmIfPresented: firstRequiresConfirmation
        ) == .deferredUntilAlertDismisses)
        #expect(router.submit(
            .push(.third, on: .history), confirmIfPresented: latestRequiresConfirmation
        ) == .deferredUntilAlertDismisses)
        #expect(router.requestWaitingForAlert == .push(.third, on: .history))
        #expect(router.pendingConfirmation == nil)

        finishAlert(alertID, on: context)
        #expect(router.requestWaitingForAlert == nil)
        #expect(router.path(for: .history).isEmpty)
        if latestRequiresConfirmation {
            #expect(router.sheet === page)
            #expect(router.deferredRequest == nil)
            let confirmation = try #require(router.pendingConfirmation)
            #expect(confirmation.request == .push(.third, on: .history))
            router.confirmNavigation(id: confirmation.id)
        } else {
            #expect(router.sheet == nil)
            #expect(router.pendingConfirmation == nil)
        }
        #expect(router.deferredRequest == .push(.third, on: .history))
        router.rootPresentation.presentationDidDismiss()
        #expect(router.path(for: .history) == [.third])
    }

    @Test(arguments: [true, false])
    func dismissAllAbsorbsIndividualDismissalsWhileAlertIsActive(allFirst: Bool) throws {
        let router = Router(
            rootDestination: .root,
            selectedScope: .home,
            rootDestinations: [.home: .first, .history: .second]
        )
        router.presentSheet(.first)
        let parent = try #require(router.sheet)
        let parentContext = router.presentationContext(for: parent)
        #expect(parentContext.present(.second) == .applied)
        let child = try #require(parent.sheet)
        let childContext = router.presentationContext(for: child)
        let alertID = try beginAlert(childContext)
        #expect(childContext.presentAlert(.message) == .queued)

        if allFirst { router.dismissAllPresentations() }
        #expect(childContext.dismiss() == .queued)
        #expect(parentContext.dismiss() == .queued)
        #expect(childContext.dismiss() == .queued)
        if !allFirst { router.dismissAllPresentations() }
        #expect(router.sheet === parent)
        #expect(parent.sheet === child)
        childContext.alertWillDismiss(id: .business(alertID))
        #expect(childContext.beginAlertCompletion(id: .business(alertID)))
        #expect(router.sheet === parent)
        childContext.alertDidDismiss(id: .business(alertID))
        #expect(router.sheet == nil)
        #expect(router.isAwaitingPresentationDismissal)
        #expect(!parentContext.isActive)
        #expect(!childContext.isActive)
        router.rootPresentation.presentationDidDismiss()

        router.presentSheet(.third)
        let reopened = try #require(router.sheet)
        childContext.alertDidDismiss(id: .business(alertID))
        router.resumePresentations()
        #expect(router.sheet === reopened)
        #expect(router.alertRoutes.isEmpty)
    }

    private func resolve(_ id: NavigationConfirmationID, on router: Router, approve: Bool) {
        if approve {
            router.confirmNavigation(id: id)
        } else {
            router.cancelConfirmation(id: id)
        }
    }

    private func beginAlert(_ context: Presentation) throws -> NavigationAlertID {
        #expect(context.presentAlert(.message) == .applied)
        let id = try #require(context.presentedAlert).id
        #expect(context.alertWillPresent(id: .business(id)))
        return id
    }

    private func finishAlert(_ id: NavigationAlertID, on context: Presentation) {
        context.alertWillDismiss(id: .business(id))
        #expect(context.beginAlertCompletion(id: .business(id)))
        context.alertDidDismiss(id: .business(id))
    }
}
