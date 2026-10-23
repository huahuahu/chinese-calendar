import Foundation

/// 提供给原生 alert 宿主的显示内容和生命周期回调；当前提示的路由与会话状态仍由 Router 管理。
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
    /// 同步启动动作处理，返回任务供需要等待处理结束的调用方使用；UIKit 宿主不等待它。
    let didDismiss: (Int?) -> Task<Void, Never>

    /// 两类提示共用系统展示与关闭生命周期，业务动作在一次性完成权限取得后执行。
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
        willPresent = { context.alertWillPresent(id: id) }
        willDismiss = { context.alertWillDismiss(id: id) }
        didDismiss = { selection in
            // 用独立 Task 等待按钮动作完成，再释放本次 alert 会话；页面重建不会取消这项任务。
            Task { @MainActor in
                guard context.beginAlertCompletion(id: id) else { return }
                if let selection, definition.buttons.indices.contains(selection) {
                    await definition.buttons[selection].perform()
                }
                context.alertDidDismiss(id: id)
            }
        }
    }
}
