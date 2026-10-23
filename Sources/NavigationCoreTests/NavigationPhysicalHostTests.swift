#if canImport(UIKit)
    @testable import NavigationCore
    import SwiftUI
    import Testing
    import UIKit

    @MainActor
    @Suite("真实 SwiftUI 宿主与 UIKit 呈现完成", .serialized)
    struct NavigationPhysicalHostTests {
        enum Scope: NavigationScope { case main }
        enum Destination: NavigationDestination { case home, first, second, target }
        enum Notice: NavigationAlertRoute { case work }
        typealias Router = NavigationRouter<Scope, Destination, Notice>
        typealias Presentation = NavigationPresentationContext<Scope, Destination, Notice>
        typealias Request = NavigationPresentationRequest<Scope, Destination, Notice>

        @Test func uiKitControlPresentsAndDismissesInTheSameWindow() async throws {
            let host = try await PhysicalNavigationHost.showUIKitControl()
            defer { host.removeFromWindow() }
            let controller = try await host.presentUIKitControl()
            #expect(controller.presentingViewController != nil)
            #expect(controller.viewIfLoaded?.window != nil)
            #expect(!controller.isBeingPresented)
            try await host.dismissUIKitControl(controller)
            #expect(controller.presentingViewController == nil)
            #expect(controller.viewIfLoaded?.window == nil)
            #expect(host.presentedController == nil)
            await host.close()
        }

        @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
        func physicalDismissalFinishesOnceAndReleasesRequestConfiguration(
            style: NavigationPresentationStyle
        ) async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "request", ledger: ledger, resource: PhysicalHostResource()
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            let observation = PhysicalDismissObservation()
            let request: Request = style == .sheet ? .sheet(.first) : .fullScreen(.first)
            let submission = router.rootPresentation.present(request, configuration: configuration) {
                observation.recordFinish()
            }
            configuration = nil
            #expect(submission.result == .applied)
            observation.controller = try await host.waitForPresentation()
            #expect(ledger.rendered.contains("request:first"))
            #expect(weakConfiguration != nil && weakResource != nil)
            #expect(observation.finishes == 0)
            #expect(submission.handle?.dismiss() == .applied)
            #expect(observation.finishes == 0)
            try await host.waitUntil { observation.finishes == 1 }
            #expect(observation.completedAfterPhysicalDismissal)
            try await host.waitUntil { weakConfiguration == nil && weakResource == nil }
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            #expect(observation.finishes == 1)
            await host.close()
        }

        @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
        func nativeUIKitDismissalCompletesTheAcceptedRequest(style: NavigationPresentationStyle) async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            let observation = PhysicalDismissObservation()
            let request: Request = style == .sheet ? .sheet(.first) : .fullScreen(.first)
            let submission = router.rootPresentation.present(request) { observation.recordFinish() }
            #expect(submission.result == .applied)
            let controller = try await host.waitForPresentation()
            observation.controller = controller
            // 模拟原生容器直接关闭，不能依赖业务 handle 预先清空 Router。
            await withCheckedContinuation { continuation in
                controller.dismiss(animated: true) { continuation.resume() }
            }
            try await host.waitUntil { observation.finishes == 1 }
            #expect(observation.completedAfterPhysicalDismissal)
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            var replacementFinishes = 0
            let replacement = router.rootPresentation.present(.sheet(.second)) { replacementFinishes += 1 }
            #expect(replacement.result == .applied)
            _ = try await host.waitForPresentation()
            replacement.handle?.dismiss()
            try await host.waitUntil { replacementFinishes == 1 }
            await host.close()
        }

        @Test func sameTurnCancellationNeverNeedsAPhysicalDismissalCallback() async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "cancelled", ledger: ledger, resource: PhysicalHostResource()
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            var finishes = 0
            let submission = router.rootPresentation.present(.sheet(.first), configuration: configuration) {
                finishes += 1
            }
            configuration = nil
            // 中间没有 await：SwiftUI 尚未取得本次 item，取消必须同步结束请求资源。
            #expect(submission.handle?.dismiss() == .applied)
            #expect(finishes == 1)
            #expect(weakConfiguration == nil && weakResource == nil)
            #expect(host.presentedController == nil)
            #expect(!ledger.rendered.contains("cancelled:first"))

            var replacementFinishes = 0
            let replacement = router.rootPresentation.present(.sheet(.first)) { replacementFinishes += 1 }
            #expect(replacement.result == .applied)
            _ = try await host.waitForPresentation()
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            #expect(replacementFinishes == 0)
            replacement.handle?.dismiss()
            try await host.waitUntil { replacementFinishes == 1 }
            #expect(finishes == 1)
            await host.close()
        }

        @Test func repeatedRouteUsesEachRequestConfigurationAndNestedPageInheritsIt() async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            var firstFinishes = 0
            let first = router.rootPresentation.present(.sheet(.first)) { firstFinishes += 1 }
            _ = try await host.waitForPresentation()
            #expect(ledger.rendered.contains("root:first"))
            first.handle?.dismiss()
            try await host.waitUntil { firstFinishes == 1 }

            let override = PhysicalHostConfiguration(name: "override", ledger: ledger)
            var overrideFinishes = 0
            let second = router.rootPresentation.present(.sheet(.first), configuration: override) {
                overrideFinishes += 1
            }
            _ = try await host.waitForPresentation()
            try await host.waitUntil { ledger.contexts[.first] != nil && ledger.rendered.contains("override:first") }
            let context = try #require(ledger.contexts[.first])
            var nestedFinishes = 0
            let nested = context.present(.fullScreen(.second)) { nestedFinishes += 1 }
            #expect(nested.result == .applied)
            _ = try await host.waitForPresentation(depth: 2)
            #expect(ledger.rendered.contains("override:second"))
            nested.handle?.dismiss()
            try await host.waitUntil { nestedFinishes == 1 }
            #expect(overrideFinishes == 0)
            second.handle?.dismiss()
            try await host.waitUntil { overrideFinishes == 1 }
            #expect(firstFinishes == 1 && nestedFinishes == 1)
            await host.close()
        }
    }

    extension NavigationPhysicalHostTests {
        @Test func ancestorPhysicalDismissalFinishesEveryChildBeforeExternalNavigationCallback() async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            var parentFinishes = 0
            var childFinishes = 0
            var pathAtFinish: [Destination] = []
            let parent = router.rootPresentation.present(.sheet(.first)) {
                parentFinishes += 1
                pathAtFinish = router.rootPresentation.context(for: .primary).path
            }
            #expect(parent.result == .applied)
            _ = try await host.waitForPresentation()
            try await host.waitUntil { ledger.contexts[.first] != nil }
            let context = try #require(ledger.contexts[.first])
            let child = context.present(.fullScreen(.second)) { childFinishes += 1 }
            #expect(child.result == .applied)
            _ = try await host.waitForPresentation(depth: 2)
            #expect(router.submit(.push(.target, on: .primary)) == .deferredUntilPresentationDismisses)
            #expect(parentFinishes == 0 && childFinishes == 0)
            #expect(router.rootPresentation.context(for: .primary).path.isEmpty)
            try await host.waitUntil { parentFinishes == 1 && childFinishes == 1 }
            #expect(host.presentedController == nil)
            #expect(pathAtFinish == [.target])
            #expect(parent.handle?.dismiss() == .noChange(.notPresented))
            #expect(child.handle?.dismiss() == .noChange(.notPresented))
            await host.close()
        }

        @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
        func dismantlingHostWaitsForPhysicalDismissalAndReleasesResources(
            style: NavigationPresentationStyle
        ) async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "teardown", ledger: ledger, resource: PhysicalHostResource()
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            let observation = PhysicalDismissObservation()
            let request: Request = style == .sheet ? .sheet(.first) : .fullScreen(.first)
            let submission = router.rootPresentation.present(request, configuration: configuration) {
                observation.recordFinish()
            }
            configuration = nil
            #expect(submission.result == .applied)
            observation.controller = try await host.waitForPresentation()
            host.replaceRootContent()
            try await host.waitUntil { observation.finishes == 1 }
            #expect(observation.completedAfterPhysicalDismissal)
            try await host.waitUntil { weakConfiguration == nil && weakResource == nil }
            #expect(router.rootPresentation.present(.sheet(.second)).result == .rejected(.hostUnavailable))
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            await host.close()
        }

        @Test func parentHostTeardownKeepsFeatureUntilDescendantAlertActionFinishes() async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let gate = PhysicalActionGate()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer {
                gate.release()
                host.removeFromWindow()
            }
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "feature", ledger: ledger, resource: PhysicalHostResource(), gate: gate
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            var parentFinishes = 0
            var alertFinishes = 0
            let parent = router.rootPresentation.present(.sheet(.first), configuration: configuration) {
                parentFinishes += 1
            }
            configuration = nil
            #expect(parent.result == .applied)
            _ = try await host.waitForPresentation()
            try await host.waitUntil { ledger.contexts[.first] != nil }
            let context = try #require(ledger.contexts[.first])
            #expect(context.present(.alert(.work), onFinish: { alertFinishes += 1 }).result == .applied)
            _ = try await host.waitForAlert()
            // 不额外保活模态的 UIKit 子控制器，否则测试自身会延长整棵 SwiftUI 渲染树的寿命。
            try #require(host.alertPresenter).dismissCurrent(selection: 0)
            try await host.waitUntil { gate.started }
            #expect(router.submit(.push(.target, on: .primary)) == .deferredUntilAlertDismisses)
            host.replaceRootContent()
            try await host.waitUntil { host.presentedController == nil }
            #expect(parentFinishes == 0 && alertFinishes == 0)
            #expect(weakConfiguration != nil && weakResource != nil)
            #expect(router.rootPresentation.context(for: .primary).path.isEmpty)
            gate.release()
            try await host.waitUntil { parentFinishes == 1 && alertFinishes == 1 }
            #expect(router.rootPresentation.context(for: .primary).path == [.target])
            try await host.waitUntil { weakConfiguration == nil && weakResource == nil }
            await host.close()
        }

        @Test func alertActionSuspensionSurvivesHostTeardownAndFinishesOnlyAfterAction() async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let gate = PhysicalActionGate()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer {
                gate.release()
                host.removeFromWindow()
            }
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "alert", ledger: ledger, resource: PhysicalHostResource(), gate: gate
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            var finishes = 0
            let submission = router.rootPresentation.present(.alert(.work), configuration: configuration) {
                finishes += 1
            }
            configuration = nil
            #expect(submission.result == .applied)
            let alert = try await host.waitForAlert()
            let presenter = try #require(host.alertPresenter)
            // 走原生按钮使用的入口；宿主实际 dismiss UIAlertController 后才会进入业务动作。
            presenter.dismissCurrent(selection: 0)
            try await host.waitUntil { gate.started }
            #expect(alert.presentingViewController == nil)
            #expect(finishes == 0)
            #expect(weakConfiguration != nil && weakResource != nil)
            var queuedFinishes = 0
            #expect(router.rootPresentation.present(.sheet(.second), onFinish: {
                queuedFinishes += 1
            }).result == .queued)
            host.replaceRootContent()
            try await host.waitUntil { queuedFinishes == 1 }
            #expect(finishes == 0)
            #expect(weakConfiguration != nil && weakResource != nil)
            gate.release()
            try await host.waitUntil { finishes == 1 }
            #expect(ledger.actions == ["alert:work"])
            try await host.waitUntil { weakConfiguration == nil && weakResource == nil }
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            await host.close()
        }
    }

    extension NavigationPhysicalHostTests {
        @Test(arguments: [false, true])
        func routerDestructionWaitsForSuspendedDescendantAction(releaseBeforeDismissal: Bool) async throws {
            var router: Router? = Router(rootDestination: .home)
            weak var weakRouter = router
            let ledger = PhysicalHostLedger()
            let gate = PhysicalActionGate()
            let host = try await PhysicalNavigationHost.show(router: #require(router), ledger: ledger)
            defer {
                gate.release()
                host.removeFromWindow()
            }
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "detached", ledger: ledger, resource: PhysicalHostResource(), gate: gate
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            var finishes: [String] = []
            let parent = router?.rootPresentation.present(.sheet(.first), configuration: configuration) {
                finishes.append("parent")
            }
            configuration = nil
            #expect(parent?.result == .applied)
            _ = try await host.waitForPresentation()
            let context = try #require(ledger.contexts[.first])
            #expect(context.present(.alert(.work), onFinish: { finishes.append("alert") }).result == .applied)
            _ = try await host.waitForAlert()
            try #require(host.alertPresenter).dismissCurrent(selection: 0)
            try await host.waitUntil { gate.started }
            if releaseBeforeDismissal { router = nil }
            host.replaceRootContent()
            try await host.waitUntil { host.presentedController == nil }
            router = nil
            #expect(weakRouter == nil)
            #expect(finishes.isEmpty)
            #expect(weakConfiguration != nil && weakResource != nil)
            gate.release()
            try await host.waitUntil { finishes == ["alert", "parent"] }
            try await host.waitUntil { weakConfiguration == nil && weakResource == nil }
            #expect(parent?.handle?.dismiss() == .noChange(.notPresented))
            await host.close()
        }
    }

    extension NavigationPhysicalHostTests {
        @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
        func sameTurnHostRemovalFinishesOnceAndReleasesConfiguration(style: NavigationPresentationStyle) async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "same-turn-teardown", ledger: ledger, resource: PhysicalHostResource()
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            var finishes = 0
            let request: Request = style == .sheet ? .sheet(.first) : .fullScreen(.first)
            let submission = router.rootPresentation.present(request, configuration: configuration) { finishes += 1 }
            configuration = nil
            // 与 present 同一 MainActor 回合移除宿主，由真实 dismantle 决定取消或关闭。
            host.replaceRootContent()
            #expect(submission.result == .applied)
            try await host.waitUntil { finishes == 1 && weakConfiguration == nil && weakResource == nil }
            #expect(host.presentedController == nil)
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            #expect(router.rootPresentation.present(.sheet(.second)).result == .rejected(.hostUnavailable))
            await host.close()
            #expect(finishes == 1)
        }

        @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen])
        func enteringPageRemovesItsHostAndFinishesOnlyAfterLeavingWindow(
            style: NavigationPresentationStyle
        ) async throws {
            let router = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: router, ledger: ledger)
            defer { host.removeFromWindow() }
            let probe = NavigationEntryTeardownProbe()
            probe.onEntry = { host.replaceRootContent() }
            var configuration: NavigationEntryTeardownConfiguration? = NavigationEntryTeardownConfiguration(
                probe: probe, resource: PhysicalHostResource()
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            let request: Request = style == .sheet ? .sheet(.first) : .fullScreen(.first)
            let submission = router.rootPresentation
                .present(request, configuration: configuration) { probe.recordFinish() }
            configuration = nil
            #expect(submission.result == .applied)
            #expect(probe.finishes == 0)
            try await host.waitUntil { probe.didTrigger }
            #expect(probe.hadPresenterAtEntry)
            #expect(probe.wasBeingPresentedAtEntry)
            try await host.waitUntil { probe.finishes == 1 && host.presentedController == nil }
            #expect(probe.finishedAfterPhysicalDismissal)
            try await host.waitUntil { weakConfiguration == nil && weakResource == nil }
            #expect(!probe.attachedAfterFinish)
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            await host.close()
            #expect(probe.finishes == 1)
        }
    }

    extension NavigationPhysicalHostTests {
        @Test(arguments: [NavigationPresentationStyle.sheet, .fullScreen], [false, true])
        func sameHostRouterReplacementFinishesOldRequestAndKeepsNewLayerUsable(
            style: NavigationPresentationStyle, afterPresentation: Bool
        ) async throws {
            let first = Router(rootDestination: .home)
            let second = Router(rootDestination: .home)
            let ledger = PhysicalHostLedger()
            let host = try await PhysicalNavigationHost.show(router: first, ledger: ledger)
            defer { host.removeFromWindow() }
            let endpoint = try #require(first.rootLayer.presentationEndpoint)
            var configuration: PhysicalHostConfiguration? = PhysicalHostConfiguration(
                name: "replaced", ledger: ledger, resource: PhysicalHostResource()
            )
            weak var weakConfiguration = configuration
            weak var weakResource = configuration?.resource
            let observation = PhysicalDismissObservation()
            let request: Request = style == .sheet ? .sheet(.first) : .fullScreen(.first)
            let submission = first.rootPresentation.present(request, configuration: configuration) {
                observation.recordFinish()
            }
            configuration = nil
            #expect(submission.result == .applied)
            if afterPresentation { observation.controller = try await host.waitForPresentation() }
            host.replaceRouter(second, ledger: ledger)
            try await host.waitUntil { observation.finishes == 1 && second.rootLayer.presentationEndpoint === endpoint }
            if afterPresentation { #expect(observation.completedAfterPhysicalDismissal) }
            try await host.waitUntil { weakConfiguration == nil && weakResource == nil }
            #expect(first.rootLayer.presentationEndpoint == nil && host.presentedController == nil)
            #expect(first.rootPresentation.present(.sheet(.second)).result == .rejected(.hostUnavailable))
            var newFinishes = 0
            let next: Request = style == .sheet ? .sheet(.second) : .fullScreen(.second)
            let replacement = second.rootPresentation.present(next) { newFinishes += 1 }
            #expect(replacement.result == .applied)
            _ = try await host.waitForPresentation()
            #expect(submission.handle?.dismiss() == .noChange(.notPresented))
            #expect(newFinishes == 0 && observation.finishes == 1)
            replacement.handle?.dismiss()
            try await host.waitUntil { newFinishes == 1 }
            await host.close()
            #expect(observation.finishes == 1 && newFinishes == 1)
        }
    }
#endif
