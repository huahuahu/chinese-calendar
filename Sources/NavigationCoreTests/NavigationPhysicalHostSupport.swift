#if canImport(UIKit)
    @testable import NavigationCore
    import SwiftUI
    import Testing
    import UIKit

    @MainActor
    final class PhysicalHostResource {}

    @MainActor
    final class PhysicalHostLedger {
        var rendered: Set<String> = []
        var contexts: [NavigationPhysicalHostTests.Destination: NavigationPhysicalHostTests.Presentation] = [:]
        var actions: [String] = []
    }

    @MainActor
    final class PhysicalDismissObservation {
        weak var controller: UIViewController?
        var finishes = 0
        var completedAfterPhysicalDismissal = false

        func recordFinish() {
            finishes += 1
            completedAfterPhysicalDismissal = controller?.presentingViewController == nil &&
                controller?.viewIfLoaded?.window == nil
        }
    }

    @MainActor
    final class PhysicalHostConfiguration: @MainActor NavigationHostConfiguration {
        typealias Scope = NavigationPhysicalHostTests.Scope
        typealias Destination = NavigationPhysicalHostTests.Destination
        typealias AlertRoute = NavigationPhysicalHostTests.Notice
        let name: String
        let ledger: PhysicalHostLedger
        let resource: PhysicalHostResource?
        let gate: PhysicalActionGate?

        init(
            name: String, ledger: PhysicalHostLedger,
            resource: PhysicalHostResource? = nil, gate: PhysicalActionGate? = nil
        ) {
            self.name = name
            self.ledger = ledger
            self.resource = resource
            self.gate = gate
        }

        func destination(for destination: Destination) -> some View {
            PhysicalHostPage(name: name, destination: destination, ledger: ledger)
        }

        func alert(
            for route: AlertRoute, presentation: NavigationPhysicalHostTests.Presentation
        ) -> NavigationAlertDefinition? {
            NavigationAlertDefinition(content: NavigationAlertContent(
                title: "提示", message: "等待业务动作完成",
                firstButton: NavigationAlertButton("继续", action: route)
            )) { [self] route in
                if let gate { await gate.pause() }
                ledger.actions.append("\(name):\(route)")
            }
        }
    }

    private struct PhysicalHostPage: View {
        let name: String
        let destination: NavigationPhysicalHostTests.Destination
        let ledger: PhysicalHostLedger
        @Environment(NavigationPhysicalHostTests.Presentation.self) private var presentation

        var body: some View {
            Text("\(name):\(destination)")
                .onAppear {
                    ledger.rendered.insert("\(name):\(destination)")
                    ledger.contexts[destination] = presentation
                }
        }
    }

    @MainActor
    final class PhysicalActionGate {
        private(set) var started = false
        private var released = false
        private var continuation: CheckedContinuation<Void, Never>?

        func pause() async {
            guard !released else { return }
            await withCheckedContinuation { continuation in
                self.continuation = continuation
                started = true
            }
        }

        func release() {
            released = true
            let continuation = continuation
            self.continuation = nil
            continuation?.resume()
        }
    }

    @MainActor
    final class PhysicalNavigationHost {
        private let windowLease: NavigationTestWindowLease
        var window: UIWindow {
            windowLease.window
        }

        private let hosting = UIHostingController(rootView: AnyView(Color.clear))
        private var appeared = false
        private weak var router: NavigationPhysicalHostTests.Router?

        private init(windowLease: NavigationTestWindowLease) {
            self.windowLease = windowLease
        }

        static func show(
            router: NavigationPhysicalHostTests.Router, ledger: PhysicalHostLedger
        ) async throws -> PhysicalNavigationHost {
            let windowLease = try await NavigationTestWindowLease.acquire()
            let host = PhysicalNavigationHost(windowLease: windowLease)
            host.router = router
            try await host.mount(navigationContent(router: router, ledger: ledger))
            return host
        }

        static func showUIKitControl() async throws -> PhysicalNavigationHost {
            let windowLease = try await NavigationTestWindowLease.acquire()
            let host = PhysicalNavigationHost(windowLease: windowLease)
            try await host.mount(Color.clear)
            return host
        }

        private func mount(_ content: some View) async throws {
            replaceContent(content)
            window.rootViewController = hosting
            window.makeKeyAndVisible()
            do {
                try await waitUntil {
                    self.appeared && self.hosting.viewIfLoaded?.window === self.window &&
                        self.window.windowScene?.activationState == .foregroundActive
                }
            } catch {
                removeFromWindow()
                throw error
            }
        }

        private static func navigationContent(
            router: NavigationPhysicalHostTests.Router, ledger: PhysicalHostLedger
        ) -> some View {
            NavigationRootView(context: router.rootPresentation)
                .navigationHost(
                    context: router.rootPresentation,
                    configuration: PhysicalHostConfiguration(name: "root", ledger: ledger)
                )
        }

        private func replaceContent(_ content: some View) {
            hosting.rootView = AnyView(content.onAppear { [weak self] in self?.appeared = true })
        }

        /// 保持相同的 SwiftUI 结构，只替换宿主输入，测试另外核对 endpoint 对象没有重建。
        func replaceRouter(_ router: NavigationPhysicalHostTests.Router, ledger: PhysicalHostLedger) {
            self.router = router
            replaceContent(Self.navigationContent(router: router, ledger: ledger))
        }

        func presentUIKitControl() async throws -> UIViewController {
            let controller = UIViewController()
            controller.view.backgroundColor = .systemBackground
            controller.modalPresentationStyle = .fullScreen
            var completed = false
            hosting.present(controller, animated: true) { completed = true }
            try await waitUntil { completed }
            return controller
        }

        func dismissUIKitControl(_ controller: UIViewController) async throws {
            var completed = false
            controller.dismiss(animated: true) { completed = true }
            try await waitUntil { completed }
        }

        var presentedController: UIViewController? {
            presentationChain.last
        }

        var alertPresenter: NavigationAlertPresenter? {
            findController(NavigationAlertPresenter.self, in: hosting)
        }

        func waitForPresentation(depth: Int = 1) async throws -> UIViewController {
            try await waitUntil {
                let chain = self.presentationChain
                guard chain.count >= depth, let controller = chain.last else { return false }
                return controller.viewIfLoaded?.window != nil && !controller.isBeingPresented
            }
            return try #require(presentedController)
        }

        func waitForAlert() async throws -> UIAlertController {
            try await waitUntil {
                guard let alert = self.presentedController as? UIAlertController else { return false }
                return alert.viewIfLoaded?.window != nil && !alert.isBeingPresented
            }
            return try #require(presentedController as? UIAlertController)
        }

        func replaceRootContent() {
            hosting.rootView = AnyView(Color.clear)
        }

        func close() async {
            defer { removeFromWindow() }
            guard presentedController != nil else { return }
            var completed = false
            hosting.dismiss(animated: false) { completed = true }
            do {
                try await waitUntil { completed }
            } catch {
                Issue.record(error, "测试宿主没有收到 UIKit 的关闭完成通知")
            }
        }

        func removeFromWindow() {
            hosting.rootView = AnyView(Color.clear)
            windowLease.release()
        }

        func waitUntil(
            timeout: Duration = .seconds(8), function: StaticString = #function, line: UInt = #line,
            _ condition: @MainActor () -> Bool
        ) async throws {
            let clock = ContinuousClock()
            let deadline = clock.now.advanced(by: timeout)
            while !condition() {
                guard clock.now < deadline else {
                    printTimeoutDiagnostics(function: function, line: line)
                    throw WaitFailure.timedOut
                }
                // 只轮询可观测条件；系统完成由 UIKit completion 与 SwiftUI onDismiss 驱动。
                try await Task.sleep(for: .milliseconds(10))
            }
        }

        private func printTimeoutDiagnostics(function: StaticString, line: UInt) {
            let scene = window.windowScene
            let connectedScenes = UIApplication.shared.connectedScenes.map {
                "\(type(of: $0)) state=\($0.activationState)"
            }.sorted()
            let chain = presentationChain.enumerated().map { index, controller in
                "\(index):\(type(of: controller)) window=\(String(describing: controller.viewIfLoaded?.window)) " +
                    "isBeingPresented=\(controller.isBeingPresented) isBeingDismissed=\(controller.isBeingDismissed)"
            }
            let nodes = router?.rootPresentation.presentedNode?.descendantsIncludingSelf.map {
                "\($0.destination) hostClaimed=\($0.lifetime.hostClaimed) finished=\($0.lifetime.finished)"
            } ?? []
            let alert = router?.rootPresentation.presentedAlert.map {
                "hostClaimed=\($0.lifetime.hostClaimed) finished=\($0.lifetime.finished)"
            } ?? "nil"
            print("""
            [NavigationPhysicalHost timeout] \(function):\(line)
            scene=\(String(describing: scene)) sceneState=\(String(describing: scene?.activationState))
            connectedScenes=\(connectedScenes)
            keyWindow=\(window.isKeyWindow) hidden=\(window.isHidden) appeared=\(appeared)
            hosting.view.window=\(String(describing: hosting.viewIfLoaded?.window))
            hostingAttachedToTestWindow=\(hosting.viewIfLoaded?.window === window)
            chain=\(chain)
            routerAlive=\(router != nil) nodes=\(nodes) rootAlert=\(alert)
            """)
        }

        private var presentationChain: [UIViewController] {
            func collect(_ controller: UIViewController) -> [UIViewController] {
                if let presented = controller.presentedViewController {
                    return [presented] + collect(presented)
                }
                for child in controller.children {
                    let chain = collect(child)
                    if !chain.isEmpty { return chain }
                }
                return []
            }
            return collect(hosting)
        }

        private func findController<Controller: UIViewController>(
            _ type: Controller.Type, in controller: UIViewController
        ) -> Controller? {
            if let match = controller as? Controller { return match }
            if let presented = controller.presentedViewController,
               let match = findController(type, in: presented) { return match }
            for child in controller.children {
                if let match = findController(type, in: child) { return match }
            }
            return nil
        }

        private enum WaitFailure: Error { case timedOut }
    }
#endif
