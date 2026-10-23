import SwiftUI
#if canImport(UIKit)
    import UIKit

    /// 仅用于确认既有 SwiftUI sheet 的物理结束，不另建呈现容器。
    @MainActor
    final class NavigationModalMount {
        private weak var modal: UIViewController?
        private var controllerID: ObjectIdentifier?
        private var completion: (() -> Void)?
        private var retainedDuringTeardown: AnyObject?
        private var teardownRequested = false
        private var observedPresentation = false
        private var dismissalStarted = false
        private weak var waitingTransition: (any UIViewControllerTransitionCoordinator)?
        private weak var completedTransition: (any UIViewControllerTransitionCoordinator)?

        init(completion: @escaping () -> Void) {
            self.completion = completion
        }

        /// make 与认领同步完成；晚到的 probe 不能复活已结束或已物理关闭的请求。
        func claim(_ controller: UIViewController, lifetime: NavigationPresentationLifetime) -> Bool {
            guard !lifetime.finished, completion != nil else { return false }
            controllerID = ObjectIdentifier(controller)
            lifetime.claimHost()
            connect(controller)
            return true
        }

        func connect(_ controller: UIViewController) {
            guard completion != nil, controllerID == ObjectIdentifier(controller) else { return }
            var root = controller
            while let parent = root.parent {
                root = parent
            }
            if root.presentingViewController != nil {
                modal = root
                observedPresentation = true
            }
            if controller.viewIfLoaded?.window != nil { observedPresentation = true }
            if teardownRequested { closeIfConnected() }
        }

        /// 销毁只能证明从未挂载的 probe 已被丢弃，不能代替已呈现模态的关闭完成。
        func probeDidDeinitialize(id: ObjectIdentifier) {
            guard controllerID == id, !observedPresentation else { return }
            didDismiss()
        }

        func didDismiss() {
            let completion = completion
            self.completion = nil
            completion?()
        }

        /// 物理关闭后仍可能等待后代 alert 的动作；由请求真正结束时解除保活。
        func releaseResources() {
            completion = nil
            retainedDuringTeardown = nil
        }

        func tearDown(keeping resource: AnyObject) {
            retainedDuringTeardown = resource
            teardownRequested = true
            if completion != nil { closeIfConnected() }
        }

        private func closeIfConnected() {
            guard completion != nil, !dismissalStarted, let modal else { return }
            if waitForTransition(in: modal) { return }
            guard let presenter = modal.presentingViewController,
                  presenter.presentedViewController === modal else { return }
            dismissalStarted = true
            // 从实际 presenter 关闭该模态及后代，避免只关闭模态自身呈现的子页面。
            presenter.dismiss(animated: true) { [self] in didDismiss() }
        }

        private func waitForTransition(in modal: UIViewController) -> Bool {
            var candidate: UIViewController? = modal
            while let current = candidate {
                if let transition = current.transitionCoordinator {
                    if completedTransition !== transition {
                        if waitingTransition === transition { return true }
                        waitingTransition = transition
                        let dismissesModal = modal.isBeingDismissed
                        let queued = transition.animate(alongsideTransition: nil) { [self, weak transition] context in
                            waitingTransition = nil
                            completedTransition = transition
                            if dismissesModal, !context.isCancelled {
                                didDismiss()
                            } else {
                                closeIfConnected()
                            }
                        }
                        // Bool 只描述动画排队，false 时 completion 仍可能执行；后续真实生命周期可以重试。
                        if !queued { waitingTransition = nil }
                        return true
                    }
                }
                candidate = current.presentedViewController
            }
            return false
        }
    }

    struct NavigationModalLifecycle: UIViewControllerRepresentable {
        let mount: NavigationModalMount
        let lifetime: NavigationPresentationLifetime

        func makeUIViewController(context: Context) -> NavigationModalLifecycleController {
            NavigationModalLifecycleController(mount: mount, lifetime: lifetime)
        }

        func updateUIViewController(_ controller: NavigationModalLifecycleController, context: Context) {
            controller.connect()
        }

        static func dismantleUIViewController(_ controller: NavigationModalLifecycleController, coordinator: ()) {
            // dismantle 发生在移除之前，只补记最后的真实关联，不把它当作 dismiss completion。
            controller.connect()
        }
    }

    final class NavigationModalLifecycleController: UIViewController {
        private var mount: NavigationModalMount?

        init(mount: NavigationModalMount, lifetime: NavigationPresentationLifetime) {
            super.init(nibName: nil, bundle: nil)
            if mount.claim(self, lifetime: lifetime) { self.mount = mount }
        }

        isolated deinit {
            mount?.probeDidDeinitialize(id: ObjectIdentifier(self))
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func loadView() {
            view = UIView()
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            connect()
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            connect()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            connect()
        }

        func connect() {
            mount?.connect(self)
        }
    }

    /// dismantle 对应真实 View 身份拆除；Tab 切换与普通 onDisappear 不触发清理。
    struct NavigationHostLifetime: UIViewControllerRepresentable {
        let detach: () -> Void

        func makeCoordinator() -> Coordinator {
            Coordinator(detach: detach)
        }

        func makeUIViewController(context: Context) -> UIViewController {
            UIViewController()
        }

        func updateUIViewController(_ controller: UIViewController, context: Context) {}
        static func dismantleUIViewController(_ controller: UIViewController, coordinator: Coordinator) {
            coordinator.detach()
        }

        final class Coordinator {
            let detach: () -> Void
            init(detach: @escaping () -> Void) {
                self.detach = detach
            }
        }
    }
#endif
