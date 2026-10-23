import Foundation
@testable import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("系统提示的类型擦除与实际完成门槛")
struct NavigationSystemAlertTests {
    fileprivate enum Tab: NavigationScope { case home }
    fileprivate enum Page: NavigationDestination { case home, detail, target }
    fileprivate enum Notice: NavigationAlertRoute { case clear, retry }
    fileprivate enum ClearAction: Hashable { case clear, cancel }
    fileprivate enum RetryAction: Hashable { case retry, cancel }

    fileprivate typealias Router = NavigationRouter<Tab, Page, Notice>
    fileprivate typealias Presentation = NavigationPresentationContext<Tab, Page, Notice>

    fileprivate final class Recorder {
        var clearActions: [ClearAction] = []
        var retryActions: [RetryAction] = []
        var contexts: [Presentation] = []
    }

    @Test func independentActionsShareTheTreeAndReceiveTheCurrentLayer() async throws {
        let router = Router(rootDestination: .home)
        router.presentSheet(.detail)
        let context = try router.presentationContext(for: #require(router.sheet))
        let recorder = Recorder()
        let configuration: any NavigationHostConfiguration<Tab, Page, Notice> =
            SystemAlertTestConfiguration(recorder: recorder)
        #expect(context.presentAlert(.clear) == .applied)
        #expect(context.presentAlert(.retry) == .queued)
        let first = try makeAlert(context, configuration: configuration)
        #expect(first.buttons.map(\.title) == ["取消清理", "清理"])
        #expect(first.buttons.map(\.isCancel) == [true, false])
        #expect(first.buttons.map(\.isDestructive) == [false, true])
        #expect(first.willPresent())
        await first.didDismiss(1).value
        #expect(recorder.clearActions.isEmpty)
        #expect(context.layer?.alertSession?.state == .presented)
        first.willDismiss()
        #expect(recorder.clearActions.isEmpty)
        await first.didDismiss(1).value
        #expect(recorder.clearActions == [.clear])
        #expect(context.presentedAlert?.destination == .retry)
        let second = try makeAlert(context, configuration: configuration)
        #expect(second.id != first.id)
        #expect(second.willPresent())
        second.willDismiss()
        await second.didDismiss(0).value
        #expect(recorder.retryActions == [.cancel])
        #expect(recorder.contexts.count == 2)
        #expect(recorder.contexts.allSatisfy { $0 === context })
        #expect(!router.hasActiveAlert)
        #expect(router.sheet != nil)
        await first.didDismiss(1).value
        await second.didDismiss(1).value
        #expect(recorder.clearActions == [.clear])
        #expect(recorder.retryActions == [.cancel])
    }

    @Test func suspendedActionBlocksQueuedAlertAndExternalNavigation() async throws {
        let router = Router(rootDestination: .home)
        router.presentSheet(.detail)
        let context = try router.presentationContext(for: #require(router.sheet))
        let recorder = Recorder()
        let gate = Gate()
        let configuration = SystemAlertTestConfiguration(
            recorder: recorder,
            beforeClearCompletes: { await gate.pause() }
        )
        context.presentAlert(.clear)
        let first = try makeAlert(context, configuration: configuration)
        #expect(first.willPresent())
        #expect(context.presentAlert(.retry) == .queued)
        #expect(router.submit(.push(.target, on: .primary), confirmIfPresented: true) == .deferredUntilAlertDismisses)
        first.willDismiss()
        let completion = first.didDismiss(1)
        await gate.waitUntilStarted()
        #expect(recorder.clearActions == [.clear])
        #expect(context.layer?.alertSession?.state == .handlingCompletion)
        #expect(context.presentedAlert == nil)
        #expect(context.layer?.queuedPresentations.count == 1)
        #expect(router.pendingConfirmation == nil)
        #expect(router.rootPresentation.context(for: .primary).path.isEmpty)
        first.willDismiss()
        await first.didDismiss(1).value
        #expect(recorder.clearActions == [.clear])
        gate.release()
        await completion.value
        #expect(context.presentedAlert?.destination == .retry)
        #expect(router.pendingConfirmation == nil)
        let second = try makeAlert(context, configuration: configuration)
        #expect(second.willPresent())
        second.willDismiss()
        await second.didDismiss(1).value
        #expect(recorder.retryActions == [.retry])
        #expect(router.pendingConfirmation?.request == .push(.target, on: .primary))
        #expect(router.rootPresentation.context(for: .primary).path.isEmpty)
        #expect(router.sheet != nil)
    }

    @Test(arguments: [nil, -1, 2, Int.max] as [Int?])
    func absentOrInvalidSelectionReleasesTheSessionWithoutAnAction(selection: Int?) async throws {
        let router = Router(rootDestination: .home)
        let context = router.rootPresentation
        let recorder = Recorder()
        let configuration = SystemAlertTestConfiguration(recorder: recorder)
        context.presentAlert(.clear)
        context.presentAlert(.retry)
        let alert = try makeAlert(context, configuration: configuration)
        #expect(alert.willPresent())
        alert.willDismiss()
        await alert.didDismiss(selection).value
        #expect(recorder.clearActions.isEmpty)
        #expect(context.layer?.alertSession == nil)
        #expect(context.presentedAlert?.destination == .retry)
        await alert.didDismiss(1).value
        #expect(recorder.clearActions.isEmpty)
        #expect(context.presentedAlert?.destination == .retry)
    }

    @Test func oldCallbacksCannotExecuteActionsOrDismissTheNextAlert() async throws {
        let router = Router(rootDestination: .home)
        let context = router.rootPresentation
        let recorder = Recorder()
        let configuration = SystemAlertTestConfiguration(recorder: recorder)
        context.presentAlert(.clear)
        context.presentAlert(.retry)
        let first = try makeAlert(context, configuration: configuration)
        #expect(first.willPresent())
        first.willDismiss()
        await first.didDismiss(0).value
        let second = try makeAlert(context, configuration: configuration)
        #expect(second.willPresent())
        #expect(!first.willPresent())
        first.willDismiss()
        await first.didDismiss(1).value
        #expect(recorder.clearActions == [.cancel])
        #expect(recorder.retryActions.isEmpty)
        #expect(context.layer?.alertSession?.id == second.id)
        #expect(context.layer?.alertSession?.state == .presented)
        #expect(context.presentedAlert?.destination == .retry)
        second.willDismiss()
        await second.didDismiss(1).value
        #expect(recorder.retryActions == [.retry])
    }

    @Test func inactiveContextCannotRunAnActionAgainstANewLayerWithTheSameID() async throws {
        let router = Router(rootDestination: .home)
        router.presentSheet(.detail)
        let oldPage = try #require(router.sheet)
        let oldContext = router.presentationContext(for: oldPage)
        let recorder = Recorder()
        let configuration = SystemAlertTestConfiguration(recorder: recorder)
        oldContext.presentAlert(.clear)
        let oldAlert = try makeAlert(oldContext, configuration: configuration)
        #expect(oldAlert.willPresent())
        oldAlert.willDismiss()
        let newPage = NavigationPresentationNode<Tab, Page, Notice>(id: oldPage.id, destination: .detail)
        router.rootLayer.presentation = newPage
        let context = router.presentationContext(for: newPage)
        context.presentAlert(.retry)
        let currentAlert = try makeAlert(context, configuration: configuration)
        #expect(currentAlert.willPresent())
        #expect(!oldContext.isActive)
        #expect(!oldAlert.willPresent())
        oldAlert.willDismiss()
        await oldAlert.didDismiss(1).value
        #expect(recorder.clearActions.isEmpty)
        #expect(recorder.retryActions.isEmpty)
        #expect(context.layer?.alertSession?.id == currentAlert.id)
        #expect(context.layer?.alertSession?.state == .presented)
        currentAlert.willDismiss()
        await currentAlert.didDismiss(1).value
        #expect(recorder.retryActions == [.retry])
    }

    @Test(arguments: [false, true])
    func navigationConfirmationUsesTheSameCompletionGate(approve: Bool) async throws {
        let router = Router(rootDestination: .home)
        router.presentSheet(.detail)
        let page = try #require(router.sheet)
        let context = router.presentationContext(for: page)
        router.submit(.push(.target, on: .primary), confirmIfPresented: true)
        let confirmation = try #require(context.confirmation)
        let definition = NavigationAlertDefinition(
            content: NavigationAlertContent(
                title: "离开", message: "是否继续？",
                firstButton: NavigationAlertButton("继续", action: true),
                cancelButton: NavigationAlertCancelButton("取消", action: false)
            )
        ) { approved in
            if approved {
                context.confirmNavigation(id: confirmation.id)
            } else {
                context.cancelNavigation(id: confirmation.id)
            }
        }
        let alert = NavigationSystemAlert(id: .confirmation(confirmation.id), definition: definition, context: context)
        #expect(alert.willPresent())
        alert.willDismiss()
        #expect(router.pendingConfirmation?.id == confirmation.id)
        await alert.didDismiss(approve ? 1 : 0).value
        #expect(router.pendingConfirmation == nil)
        #expect(!router.hasActiveAlert)
        #expect(router.rootPresentation.context(for: .primary).path.isEmpty)
        if approve {
            #expect(router.sheet == nil)
            #expect(router.isAwaitingPresentationDismissal)
            router.rootPresentation.presentationDidDismiss()
            #expect(router.rootPresentation.context(for: .primary).path == [.target])
        } else {
            #expect(router.sheet === page)
        }
        await alert.didDismiss(1).value
        #expect(router.rootPresentation.context(for: .primary).path == (approve ? [.target] : []))
    }
}

private extension NavigationSystemAlertTests {
    func makeAlert(
        _ context: Presentation,
        configuration: any NavigationHostConfiguration<Tab, Page, Notice>
    ) throws -> NavigationSystemAlert {
        let node = try #require(context.presentedAlert)
        let definition = try #require(configuration.alert(for: node.destination, presentation: context))
        return NavigationSystemAlert(id: .business(node.id), definition: definition, context: context)
    }

    /// 由测试显式释放处理中的动作，观察挂起期间的真实会话状态，不猜测执行时长。
    final class Gate {
        private var started = false
        private var startWaiters: [CheckedContinuation<Void, Never>] = []
        private var releaseContinuation: CheckedContinuation<Void, Never>?

        func waitUntilStarted() async {
            guard !started else { return }
            await withCheckedContinuation { startWaiters.append($0) }
        }

        func pause() async {
            await withCheckedContinuation { continuation in
                releaseContinuation = continuation
                started = true
                let waiters = startWaiters
                startWaiters.removeAll()
                for waiter in waiters {
                    waiter.resume()
                }
            }
        }

        func release() {
            let continuation = releaseContinuation
            releaseContinuation = nil
            continuation?.resume()
        }
    }
}

private struct SystemAlertTestConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = NavigationSystemAlertTests.Tab
    typealias Destination = NavigationSystemAlertTests.Page
    typealias AlertRoute = NavigationSystemAlertTests.Notice
    typealias Presentation = NavigationSystemAlertTests.Presentation

    let recorder: NavigationSystemAlertTests.Recorder
    var beforeClearCompletes: @MainActor () async -> Void = {}

    func destination(for destination: Destination) -> some View {
        Color.clear
    }

    func alert(for route: AlertRoute, presentation: Presentation) -> NavigationAlertDefinition? {
        switch route {
        case .clear:
            NavigationAlertDefinition(
                content: NavigationAlertContent(
                    title: "清理提示", message: "清理内容",
                    firstButton: NavigationAlertButton(
                        "清理",
                        action: NavigationSystemAlertTests.ClearAction.clear,
                        role: .destructive
                    ),
                    cancelButton: NavigationAlertCancelButton("取消清理", action: .cancel)
                )
            ) { action in
                recorder.clearActions.append(action)
                recorder.contexts.append(presentation)
                if action == .clear { await beforeClearCompletes() }
            }
        case .retry:
            NavigationAlertDefinition(
                content: NavigationAlertContent(
                    title: "重试提示", message: "重试内容",
                    firstButton: NavigationAlertButton("重试", action: NavigationSystemAlertTests.RetryAction.retry),
                    cancelButton: NavigationAlertCancelButton("取消重试", action: .cancel)
                )
            ) { action in
                recorder.retryActions.append(action)
                recorder.contexts.append(presentation)
            }
        }
    }
}
