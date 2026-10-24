import Foundation

/// 记录 alert 是否已关闭、按钮操作是否已完成，并防止重复执行按钮操作。
/// NavigationSystemAlert 的回调持有此 session，因此 Router 释放后仍能完成按钮操作并通知 session 结束。
@MainActor
final class NavigationAlertSession {
    enum State {
        /// 已创建 session，准备显示 alert；展示动画可能尚未完成。
        case presented
        /// 正在关闭 alert，等待 UIKit 的关闭完成回调。
        case dismissing
        /// 关闭已完成，正在处理回调及异步业务动作。
        case handlingCompletion
        /// alert 已关闭且按钮操作已完成，忽略后续重复回调。
        case finished
    }

    let id: NavigationSystemAlertID
    let lifetime: NavigationPresentationLifetime?
    private(set) var state: State = .presented

    init(id: NavigationSystemAlertID, lifetime: NavigationPresentationLifetime? = nil) {
        self.id = id
        self.lifetime = lifetime
    }

    func beginDismissal() {
        guard state == .presented else { return }
        state = .dismissing
    }

    func beginCompletion() -> Bool {
        guard state == .dismissing else { return false }
        state = .handlingCompletion
        return true
    }

    /// 只标记 session 已结束；结束通知和后续导航由 completeAlertSession 继续处理。
    func endCompletion() -> Bool {
        guard state == .handlingCompletion else { return false }
        state = .finished
        return true
    }
}
