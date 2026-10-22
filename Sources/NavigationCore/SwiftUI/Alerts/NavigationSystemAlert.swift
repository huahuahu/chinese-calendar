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
    let didDismiss: (Int?) -> Void
}
