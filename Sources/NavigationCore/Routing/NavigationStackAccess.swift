/// 提供两个判断：当前栈是否仍有效、现在是否允许修改路径。
/// NavigationContext 只使用判断结果，不需要了解模态或确认请求。
/// 创建方提供实时判断规则；闭包应避免强引用 Router，防止它因旧页面仍持有 Context 而无法释放。
@MainActor
struct NavigationStackAccess {
    let isActive: () -> Bool
    let canMutate: () -> Bool

    static let inactive = NavigationStackAccess(isActive: { false }, canMutate: { false })
}
