import Foundation

/// 记录系统提示的实际生命周期。宿主保留会话后，即使 Router 已释放也能完成已选择的动作。
@MainActor
final class NavigationAlertSession {
    enum State {
        /// 会话已占用，不代表展示动画已经结束。
        case presented
        /// 正在关闭，等待 UIKit completion。
        case dismissing
        /// 关闭已完成，正在处理回调及异步业务动作。
        case handlingCompletion
        /// 系统关闭和业务动作均已完成，重复回调不再获得处理权。
        case finished
    }

    let id: NavigationSystemAlertID
    let lifetime: NavigationPresentationLifetime?
    /// 导航确认同样可能阻塞祖先结束，因此无业务 lifetime 时也保留内部完成身份。
    let completionLifetime: NavigationPresentationLifetime
    private(set) var state: State = .presented

    init(id: NavigationSystemAlertID, lifetime: NavigationPresentationLifetime? = nil) {
        self.id = id
        self.lifetime = lifetime
        completionLifetime = lifetime ?? NavigationPresentationLifetime()
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

    /// 此方法只结束处理状态；仍在 Router 中时，由 Router 事务统一通知 lifetime。
    func endCompletion() -> Bool {
        guard state == .handlingCompletion else { return false }
        state = .finished
        return true
    }
}
