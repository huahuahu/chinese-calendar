@MainActor
protocol NavigationPresentationCancelling: AnyObject {
    func dismiss(lifetime: NavigationPresentationLifetime) -> NavigationPresentationResult
}

/// 只允许结束本次请求；不暴露节点、内部身份或导航树，也不保活 Router。
@MainActor
public final class NavigationPresentationHandle {
    private weak var router: (any NavigationPresentationCancelling)?
    private let lifetime: NavigationPresentationLifetime

    init(router: any NavigationPresentationCancelling, lifetime: NavigationPresentationLifetime) {
        self.router = router
        self.lifetime = lifetime
    }

    /// 尚未展示时取消请求；宿主已接手时沿正常关闭流程等待实际结束。
    @discardableResult
    public func dismiss() -> NavigationPresentationResult {
        guard !lifetime.finished, let router else { return .noChange(.notPresented) }
        return router.dismiss(lifetime: lifetime)
    }
}
