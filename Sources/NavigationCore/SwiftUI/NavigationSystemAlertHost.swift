import SwiftUI
#if canImport(UIKit)
    import UIKit

    /// 使用本层的 UIKit 容器展示原生 alert，并报告真正的关闭完成。
    struct NavigationSystemAlertHost: UIViewControllerRepresentable {
        let alert: NavigationSystemAlert?

        func makeUIViewController(context: Context) -> NavigationAlertPresenter {
            NavigationAlertPresenter()
        }

        func updateUIViewController(_ controller: NavigationAlertPresenter, context: Context) {
            controller.desiredAlert = alert
            controller.scheduleUpdate()
        }

        static func dismantleUIViewController(_ controller: NavigationAlertPresenter, coordinator: ()) {
            controller.desiredAlert = nil
            controller.dismissCurrent(selection: nil)
        }
    }

    final class NavigationAlertPresenter: UIViewController {
        var desiredAlert: NavigationSystemAlert?
        private var currentAlert: NavigationSystemAlert?
        private var controller: UIAlertController?
        private var isClosing = false
        private var updateTask: Task<Void, Never>?

        override func loadView() {
            view = UIView()
            view.backgroundColor = .clear
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            scheduleUpdate()
        }

        func scheduleUpdate() {
            updateTask?.cancel()
            // 从 SwiftUI 的更新调用退出后再修改可观察状态，不使用延时猜测动画结束。
            updateTask = Task { @MainActor [weak self] in
                guard !Task.isCancelled else { return }
                self?.updatePresentation()
            }
        }

        private func updatePresentation() {
            guard !isClosing else { return }
            if let currentAlert {
                if currentAlert.id != desiredAlert?.id { dismissCurrent(selection: nil) }
                return
            }
            guard viewIfLoaded?.window != nil, presentedViewController == nil,
                  let alert = desiredAlert, alert.willPresent() else { return }
            currentAlert = alert
            let controller = UIAlertController(title: alert.title, message: alert.message, preferredStyle: .alert)
            self.controller = controller
            for (index, button) in alert.buttons.enumerated() {
                let style: UIAlertAction.Style = button
                    .isCancel ? .cancel : (button.isDestructive ? .destructive : .default)
                controller.addAction(UIAlertAction(title: button.title, style: style) { [weak self] _ in
                    self?.dismissCurrent(selection: index)
                })
            }
            present(controller, animated: true)
        }

        func dismissCurrent(selection: Int?) {
            guard !isClosing, let controller, let alert = currentAlert else { return }
            isClosing = true
            alert.willDismiss()
            // 明确请求关闭并等待 UIKit completion；按钮回调本身不代表动画已结束。
            controller.dismiss(animated: true) { [self] in
                guard currentAlert?.id == alert.id else { return }
                self.controller = nil
                currentAlert = nil
                isClosing = false
                alert.didDismiss(selection)
                scheduleUpdate()
            }
        }
    }
#endif
