/// 提供有效性查询和当前修改被拒绝的原因，nil 表示允许修改。
/// NavigationContext 只使用判断结果，不直接依赖 Router 或模态状态。
/// 创建方提供实时判断规则；闭包应避免强引用 Router，防止它因旧页面仍持有 Context 而无法释放。
@MainActor
struct NavigationStackAccess {
    let isActive: () -> Bool
    let rejectionReason: () -> NavigationRejectionReason?

    static let inactive = unavailable(.inactiveContext)

    static func unavailable(_ reason: NavigationRejectionReason) -> Self {
        Self(isActive: { false }, rejectionReason: { reason })
    }
}
