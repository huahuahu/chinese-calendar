@testable import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("呈现宿主的层归属切换")
struct NavigationEndpointTests {
    fileprivate enum Scope: NavigationScope { case main }
    fileprivate enum Route: NavigationDestination { case home, detail }
    fileprivate enum Notice: NavigationAlertRoute { case message }
    private typealias Router = NavigationRouter<Scope, Route, Notice>
    private typealias Endpoint = NavigationPresentationEndpoint<Scope, Route, Notice>
    private typealias Request = NavigationPresentationRequest<Scope, Route, Notice>
    private typealias Configuration = EndpointTestConfiguration

    @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func rebindFinishesUnclaimedRequestAndRejectsOldContext(style: NavigationPresentationStyle) async {
        let first = Router(rootDestination: .home)
        let second = Router(rootDestination: .home)
        let endpoint = Endpoint()
        endpoint.attach(context: first.rootPresentation, configuration: Configuration())
        weak var weakConfiguration: Configuration?
        weak var weakCapture: FinishCapture?
        var finishes = 0
        var submission: NavigationPresentationSubmission?
        do {
            let configuration = Configuration()
            let capture = FinishCapture()
            weakConfiguration = configuration
            weakCapture = capture
            let request: Request = style == .sheet ? .sheet(.detail) : .fullScreen(.detail)
            submission = first.rootPresentation.present(request, configuration: configuration) {
                capture.finished = true
                finishes += 1
            }
        }
        #expect(submission?.result == .applied)
        #expect(weakConfiguration != nil && weakCapture != nil)
        let teardown = endpoint.attach(context: second.rootPresentation, configuration: Configuration())
        #expect(first.rootLayer.presentationEndpoint == nil)
        #expect(second.rootLayer.presentationEndpoint === endpoint)
        #expect(finishes == 0)
        #expect(first.rootPresentation.present(.sheet(.detail)).result == .rejected(.hostUnavailable))
        await teardown?.value
        #expect(first.presentedNode == nil && !first.isAwaitingPresentationDismissal)
        #expect(finishes == 1 && weakConfiguration == nil && weakCapture == nil)
        let stale = endpoint.submit(
            .sheet(.detail), from: first.rootPresentation, configuration: Configuration(), onFinish: { finishes += 1 }
        )
        #expect(stale.result == .rejected(.hostUnavailable) && stale.handle == nil)
        #expect(submission?.handle?.dismiss() == .noChange(.notPresented))
        endpoint.detach()
        #expect(finishes == 1)
    }

    @Test func oldCompletionCanSubmitToNewLayerWithoutBeingTornDown() async throws {
        let first = Router(rootDestination: .home)
        let second = Router(rootDestination: .home)
        let endpoint = Endpoint()
        endpoint.attach(context: first.rootPresentation, configuration: Configuration())
        let newConfiguration = Configuration()
        var oldFinishes = 0
        var newFinishes = 0
        var newSubmission: NavigationPresentationSubmission?
        let oldSubmission = first.rootPresentation.present(.sheet(.detail)) {
            oldFinishes += 1
            #expect(first.rootPresentation.present(.sheet(.detail)).result == .rejected(.hostUnavailable))
            newSubmission = second.rootPresentation.present(.sheet(.detail)) { newFinishes += 1 }
        }
        await endpoint.attach(context: second.rootPresentation, configuration: newConfiguration)?.value
        #expect(oldFinishes == 1 && newFinishes == 0)
        #expect(newSubmission?.result == .applied)
        let node = try #require(second.presentedNode)
        let record = try #require(endpoint.record(for: node.lifetime))
        #expect(record.configuration as? Configuration === newConfiguration)
        #expect(oldSubmission.handle?.dismiss() == .noChange(.notPresented))
        #expect(second.presentedNode === node)
        endpoint.detach()
        #expect(oldFinishes == 1 && newFinishes == 1)
    }

    @Test func sameLayerScopedContextKeepsAcceptedRequest() throws {
        let router = Router(rootDestination: .home)
        let root = router.rootPresentation
        let scoped = root.scoped(to: .primary)
        let endpoint = Endpoint()
        endpoint.attach(context: root, configuration: Configuration())
        var finishes = 0
        let submission = root.present(.sheet(.detail)) { finishes += 1 }
        let node = try #require(router.presentedNode)
        #expect(scoped !== root && scoped.layer === root.layer)
        endpoint.attach(context: scoped, configuration: Configuration())
        endpoint.attach(context: scoped.unscoped(), configuration: Configuration())
        #expect(finishes == 0 && router.presentedNode === node)
        #expect(scoped.presentationEndpoint === endpoint && root.presentationEndpoint === endpoint)
        #expect(submission.handle?.dismiss() == .applied)
        #expect(finishes == 1)
        let next = scoped.present(.sheet(.detail))
        #expect(next.result == .applied)
        endpoint.detach()
    }
}

extension NavigationEndpointTests {
    @Test(arguments: [false, true])
    func invalidContextRebindRevokesPreviousLayerAndAllowsRecovery(retainsInvalidLayer: Bool) async throws {
        let first = Router(rootDestination: .home)
        let second = Router(rootDestination: .home)
        let endpoint = Endpoint()
        endpoint.attach(context: first.rootPresentation, configuration: Configuration())
        var finishes = 0
        let submission = first.rootPresentation.present(.sheet(.detail)) { finishes += 1 }
        var expiredRouter: Router? = Router(rootDestination: .home)
        let expired = try #require(expiredRouter?.rootPresentation)
        let retainedLayer = retainsInvalidLayer ? expiredRouter?.rootLayer : nil
        defer { withExtendedLifetime(retainedLayer) {} }
        expiredRouter = nil
        #expect(!expired.isActive)
        #expect((expired.layer != nil) == retainsInvalidLayer)
        await endpoint.attach(context: expired, configuration: Configuration())?.value
        #expect(first.rootLayer.presentationEndpoint == nil && finishes == 1)
        #expect(first.rootPresentation.present(.sheet(.detail)).result == .rejected(.hostUnavailable))
        #expect(expired.present(.sheet(.detail)).result == .rejected(.inactiveContext))
        await endpoint.attach(context: second.rootPresentation, configuration: Configuration())?.value
        #expect(second.rootLayer.presentationEndpoint === endpoint)
        #expect(second.rootPresentation.present(.sheet(.detail)).result == .applied)
        #expect(submission.handle?.dismiss() == .noChange(.notPresented))
        endpoint.detach()
        #expect(finishes == 1)
    }

    @Test func rebindFinishesEveryUnclaimedQueuedRequestAndReleasesDefaultConfiguration() async {
        let first = Router(rootDestination: .home)
        let second = Router(rootDestination: .home)
        let endpoint = Endpoint()
        weak var weakConfiguration: Configuration?
        var finishes: [String] = []
        do {
            let configuration = Configuration()
            weakConfiguration = configuration
            endpoint.attach(context: first.rootPresentation, configuration: configuration)
        }
        #expect(first.rootPresentation.present(.alert(.message), onFinish: { finishes.append("alert") })
            .result == .applied)
        #expect(first.rootPresentation.present(.sheet(.detail), onFinish: { finishes.append("queued") })
            .result == .queued)
        await endpoint.attach(context: second.rootPresentation, configuration: Configuration())?.value
        #expect(finishes == ["alert", "queued"])
        #expect(first.rootLayer.queuedPresentations.isEmpty && first.rootLayer.presentedContent == nil)
        #expect(weakConfiguration == nil)
        endpoint.detach()
        #expect(finishes == ["alert", "queued"])
    }

    @Test func reentrantDetachDuringRebindCannotReactivateEndpoint() async {
        let first = Router(rootDestination: .home)
        let second = Router(rootDestination: .home)
        let endpoint = Endpoint()
        endpoint.attach(context: first.rootPresentation, configuration: Configuration())
        var oldFinishes = 0
        var newFinishes = 0
        var newSubmission: NavigationPresentationSubmission?
        let oldSubmission = first.rootPresentation.present(.sheet(.detail)) {
            oldFinishes += 1
            newSubmission = second.rootPresentation.present(.sheet(.detail)) { newFinishes += 1 }
            endpoint.detach()
        }
        await endpoint.attach(context: second.rootPresentation, configuration: Configuration())?.value
        #expect(newSubmission?.result == .applied)
        #expect(oldFinishes == 1 && newFinishes == 1)
        #expect(first.rootLayer.presentationEndpoint == nil && second.rootLayer.presentationEndpoint == nil)
        await endpoint.attach(context: second.rootPresentation, configuration: Configuration())?.value
        #expect(second.rootPresentation.present(.sheet(.detail)).result == .rejected(.hostUnavailable))
        #expect(oldSubmission.handle?.dismiss() == .noChange(.notPresented))
        #expect(newSubmission?.handle?.dismiss() == .noChange(.notPresented))
    }

    @Test func retiredClaimedRecordIsTornDownOnceAcrossFurtherReattachments() async throws {
        let first = Router(rootDestination: .home)
        let second = Router(rootDestination: .home)
        let third = Router(rootDestination: .home)
        let endpoint = Endpoint()
        endpoint.attach(context: first.rootPresentation, configuration: Configuration())
        var oldFinishes = 0
        let submission = first.rootPresentation.present(.alert(.message)) { oldFinishes += 1 }
        let lifetime = try #require(first.rootLayer.alert?.lifetime)
        let record = try #require(endpoint.record(for: lifetime))
        lifetime.claimHost()
        var closeRequests = 0
        record.tearDownPresentation = { closeRequests += 1 }
        await endpoint.attach(context: second.rootPresentation, configuration: Configuration())?.value
        #expect(closeRequests == 1 && oldFinishes == 0)
        var secondFinishes = 0
        #expect(second.rootPresentation.present(.sheet(.detail), onFinish: { secondFinishes += 1 }).result == .applied)
        await endpoint.attach(context: third.rootPresentation, configuration: Configuration())?.value
        #expect(closeRequests == 1 && oldFinishes == 0 && secondFinishes == 1)
        endpoint.detach()
        #expect(closeRequests == 1 && oldFinishes == 0)
        // 这里只验证重复拆除不会再次调用旧关闭入口；真实物理完成由 App-hosted 用例覆盖。
        lifetime.finish()
        #expect(oldFinishes == 1)
        #expect(submission.handle?.dismiss() == .noChange(.notPresented))
    }

    @Test func hostDetachBeforeRetiredCleanupStillFinishesOnce() async {
        let first = Router(rootDestination: .home)
        let second = Router(rootDestination: .home)
        let endpoint = Endpoint()
        endpoint.attach(context: first.rootPresentation, configuration: Configuration())
        var finishes = 0
        let submission = first.rootPresentation.present(.sheet(.detail)) { finishes += 1 }
        let teardown = endpoint.attach(context: second.rootPresentation, configuration: Configuration())
        endpoint.detach()
        #expect(finishes == 1)
        await teardown?.value
        #expect(finishes == 1)
        #expect(first.rootLayer.presentationEndpoint == nil && second.rootLayer.presentationEndpoint == nil)
        #expect(second.rootPresentation.present(.sheet(.detail)).result == .rejected(.hostUnavailable))
        #expect(submission.handle?.dismiss() == .noChange(.notPresented))
    }

    @MainActor
    private final class FinishCapture {
        var finished = false
    }
}

@MainActor
private final class EndpointTestConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = NavigationEndpointTests.Scope
    typealias Destination = NavigationEndpointTests.Route
    typealias AlertRoute = NavigationEndpointTests.Notice

    func destination(for destination: Destination) -> some View {
        Text(String(describing: destination))
    }
}
