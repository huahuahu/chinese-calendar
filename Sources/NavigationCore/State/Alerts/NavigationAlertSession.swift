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

    let id: NavigationSystemAlertID
    var state: State = .presented
}
