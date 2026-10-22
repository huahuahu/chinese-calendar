import Foundation

/// 记录系统提示的实际生命周期，防止数据清空后立即展示下一个提示。
struct NavigationAlertSession {
    enum State {
        /// 会话已占用，不代表展示动画已经结束。
        case presented
        /// 正在关闭，等待 UIKit completion。
        case dismissing
        /// 关闭已完成，正在处理回调及异步业务动作。
        case handlingCompletion
    }

    let id: UUID
    /// 标记导航框架专用的离开确认，对应 Router 中待处理的 NavigationConfirmation。
    /// true 表示按钮用于批准或取消该导航请求；业务 alert（包括删除等确认提示）均为 false。
    let isConfirmation: Bool
    var state: State = .presented
}
