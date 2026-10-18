import Foundation

/// 仅供系统适配层使用的显示配置。持久状态仍是 Router 中的路由数据。
struct NavigationSystemAlert {
    struct Button {
        let title: String
        let isCancel: Bool
        let isDestructive: Bool
    }

    let id: UUID
    let title: String
    let message: String
    let buttons: [Button]
    let willPresent: () -> Bool
    let willDismiss: () -> Void
    let didDismiss: (Int?) -> Void
}
