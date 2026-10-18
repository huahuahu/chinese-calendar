/// 标识同一呈现层中的某个导航栈。
///
/// 例如 App 根层和一个多 Tab 模态都可以有“历史”栈，它们保存的路径互不影响。
/// 因此在整个 Router 中查找一个栈时，需要同时知道它属于哪一层、使用哪个栈 ID。
public enum NavigationStackID<Scope: Hashable>: Hashable {
    /// 普通模态默认使用的栈。App 根层的栈使用 scope 命名。
    case primary
    /// 由业务命名的栈，通常对应 App 根界面或模态内部的一个 Tab。
    case scope(Scope)
}

extension NavigationStackID: Codable where Scope: Codable {}
