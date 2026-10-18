import Observation

/// 供页面操作自己所在的导航栈，提供 path、push 和 pop。
///
/// 一个栈的根页面及其 push 页面共享同一个 Context；不同 Tab 使用不同的 Context。
/// 路径直接保存在 NavigationStackState 中，这里根据传入的规则判断是否还能访问和修改。
/// 打开或关闭模态时，页面单独读取环境中的 NavigationPresentationContext。
///
/// 通过 Router 或呈现 Context 获取实例，再由 NavigationScopeView 放入页面环境。
/// 跨 Tab 跳转或需要先关闭模态的 Deep Link 请求，交给根 Router 处理。
@MainActor
@Observable
public final class NavigationContext<Scope: Hashable, Destination: Hashable> {
    /// 这个栈在所属呈现层中的 ID。其他层可以使用相同 ID，它们的路径互不影响。
    public let id: NavigationStackID<Scope>
    @ObservationIgnored private(set) weak var state: NavigationStackState<Destination>?
    private let access: NavigationStackAccess

    init(
        id: NavigationStackID<Scope>,
        state: NavigationStackState<Destination>?,
        access: NavigationStackAccess
    ) {
        self.id = id
        self.state = state
        self.access = access
    }

    /// 这个 Context 是否仍可访问原来的栈。未选中的 Tab 也可以有效。
    /// 具体规则由创建方提供；原栈失效后，出现相同 ID 的新栈也不会让它重新生效。
    public var isActive: Bool {
        state != nil && access.isActive()
    }

    private var canMutate: Bool {
        isActive && access.canMutate()
    }

    /// 这个栈中已经 push 的页面列表，不包含栈的根页面。
    ///
    /// NavigationStack 绑定此属性后，返回手势、NavigationLink(value:) 和代码中的 push/pop
    /// 都会读写同一份路径。Context 失效时读到空数组；不允许修改时忽略赋值。
    public var path: [Destination] {
        get { isActive ? state?.path ?? [] : [] }
        set {
            guard canMutate else { return }
            state?.path = newValue
        }
    }

    /// 在当前栈中 push 一个页面，保留当前 Tab 选择和其他栈的路径。
    /// - Returns: 成功把页面加入路径时返回 true；Context 失效或不允许修改时返回 false。
    @discardableResult
    public func push(_ destination: Destination) -> Bool {
        guard canMutate else { return false }
        path.append(destination)
        return true
    }

    /// 返回当前栈的上一页。已在根页面时不执行操作，也不会关闭所在模态。
    /// - Returns: 成功移除最后一个 push 页面时返回 true，否则返回 false。
    @discardableResult
    public func pop() -> Bool {
        guard canMutate, !path.isEmpty else { return false }
        path.removeLast()
        return true
    }
}
