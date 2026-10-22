// swiftformat:disable modifierOrder

/// 标识同一 NavigationLayer 中的某个导航栈。
///
/// 例如 App 根层和一个多 Tab 模态都可以有“历史”栈，它们保存的路径互不影响。
/// 因此在整个 Router 中查找一个栈时，需要同时知道它属于哪一层、使用哪个栈 ID。
nonisolated public enum NavigationStackID<Scope: NavigationScope>: Hashable {
    /// 默认导航栈。Core 提供单栈容器时使用，适用于根层和模态层。
    case primary
    /// 由业务命名的导航栈，不限定容器类型或所在层。
    case scope(Scope)
}
