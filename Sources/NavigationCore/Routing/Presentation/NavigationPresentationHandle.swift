@MainActor
protocol NavigationPresentationCancelling: AnyObject {
    func dismiss(lifetime: NavigationPresentationLifetime) -> NavigationPresentationResult
}

/// 用于取消或关闭创建此 handle 的那一次 presentation request。
/// 不提供导航状态查询；仅弱引用 Router，不延长 Router 的生命周期。
@MainActor
public final class NavigationPresentationHandle {
    private weak var router: (any NavigationPresentationCancelling)?
    private weak var lifetime: NavigationPresentationLifetime?

    init(router: any NavigationPresentationCancelling, lifetime: NavigationPresentationLifetime) {
        self.router = router
        self.lifetime = lifetime
    }

    /// presentation host 尚未开始处理时直接取消；否则请求关闭，页面的关闭通知由 SwiftUI onDismiss 提供。
    @discardableResult
    public func dismiss() -> NavigationPresentationResult {
        guard let lifetime, !lifetime.finished, let router else { return .noChange(.notPresented) }
        return router.dismiss(lifetime: lifetime)
    }
}
