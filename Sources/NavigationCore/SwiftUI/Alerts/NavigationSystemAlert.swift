import Foundation

/// 提供给 NavigationAlertPresenter 的显示内容和生命周期回调；当前 alert 的路由与 session 状态仍由 Router 管理。
struct NavigationSystemAlert {
    struct Button {
        let title: String
        let isCancel: Bool
        let isDestructive: Bool
    }

    let id: NavigationSystemAlertID
    let title: String
    let message: String
    let buttons: [Button]
    let willPresent: () -> Bool
    let willDismiss: () -> Void
    /// 同步启动按钮操作的 Task 并返回；需要等待的调用方可 await，NavigationAlertPresenter 不等待它。
    let didDismiss: (Int?) -> Task<Void, Never>

    /// 业务 alert 和 confirmation 都由 UIKit 显示；关闭完成后执行所选按钮的操作，并防止重复执行。
    init(
        id: NavigationSystemAlertID,
        definition: NavigationAlertDefinition,
        context: NavigationPresentationContext<
            some NavigationScope,
            some NavigationDestination,
            some NavigationAlertRoute
        >
    ) {
        self.id = id
        title = String(localized: definition.title)
        message = String(localized: definition.message)
        buttons = definition.buttons.map { button in
            Button(
                title: String(localized: button.title),
                isCancel: button.isCancel, isDestructive: button.isDestructive
            )
        }
        var session: NavigationAlertSession?
        willPresent = {
            guard session == nil, let claimed = context.claimAlertSession(id: id) else { return false }
            session = claimed
            return true
        }
        willDismiss = {
            session?.beginDismissal()
            context.alertWillDismiss(id: id)
        }
        didDismiss = { selection in
            // 用独立 Task 等待按钮操作完成，再结束本次 alert session；页面重建不会取消这项 Task。
            Task { @MainActor in
                guard let session, session.beginCompletion() else { return }
                if let selection, definition.buttons.indices.contains(selection) {
                    await definition.buttons[selection].perform()
                }
                context.completeAlertSession(session)
            }
        }
    }
}
