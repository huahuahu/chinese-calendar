import Observation

/// 保存一个呈现层的导航状态。App 根界面和每个模态页面各有自己的一层。
///
/// 一层可以包含多个导航栈，例如多个 Tab，但同一时刻只能直接展示一个页面模态或业务 alert。
/// 页面模态有自己的层，可以继续打开下一层；alert 没有下一层，后续提示先排队。
/// Router 和模态节点持有这些状态，页面通过对应的 Context 操作它们。
@MainActor
@Observable
final class NavigationLayer<Scope: Hashable, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute> {
    var route: NavigationLayerRoute<Destination>
    var id: NavigationLayerID {
        route.id
    }

    /// 当前选中的导航栈。切换 Tab 时，其他栈已经 push 的页面会保留。
    var selectedStack: NavigationStackID<Scope>
    /// 当前呈现层拥有的导航栈；每个栈分别保存根页面的路由数据和 push 路径。
    private(set) var stacks: [NavigationStackID<Scope>: NavigationStackState<Destination>] = [:]

    /// 读取时汇总各栈的根页面路由数据，赋值时更新各栈中保存的数据。
    /// 这里不另存一份字典；新值中没有的栈会清除其根页面路由数据。
    var roots: [NavigationStackID<Scope>: Destination] {
        get { stacks.compactMapValues(\.rootDestination) }
        set {
            for (id, state) in stacks {
                state.rootDestination = newValue[id]
            }
            for (id, root) in newValue where stacks[id] == nil {
                stack(for: id).rootDestination = root
            }
        }
    }

    /// 读取时汇总各栈的 push 路径，赋值时更新各栈中保存的路径。
    /// 整体替换时保留原来的栈对象，让页面已持有的 Context 继续读写它们。
    var paths: [NavigationStackID<Scope>: [Destination]] {
        get { stacks.compactMapValues(\.path) }
        set {
            for (id, state) in stacks {
                state.path = newValue[id]
            }
            for (id, path) in newValue where stacks[id] == nil {
                stack(for: id).path = path
            }
        }
    }

    /// 页面模态和业务 alert 共用这一份呈现状态。
    var presentedContent: NavigationPresentation<Scope, Destination, AlertRoute>?
    /// 当前 alert 结束后依次处理的数据请求，不在已有 alert 上叠加提示。
    var queuedPresentations: [NavigationPresentation<Scope, Destination, AlertRoute>] = []
    /// 系统已开始展示或正在关闭的 alert；业务动作处理完成后才释放这次会话。
    var alertSession: NavigationAlertSession?

    var presentation: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        get {
            guard case let .page(node) = presentedContent else { return nil }
            return node
        }
        set {
            if presentation != nil, newValue == nil { isAwaitingDismissal = true }
            presentedContent = newValue.map(NavigationPresentation.page)
        }
    }

    var alert: NavigationAlertNode<AlertRoute>? {
        guard case let .alert(node) = presentedContent else { return nil }
        return node
    }

    /// 子模态的数据已清空，正在等待界面容器通知关闭动画完成。
    /// 如果是根层，等待中的跨 Tab 或 Deep Link 跳转也必须等到这时才能执行。
    var isAwaitingDismissal = false

    init(
        route: NavigationLayerRoute<Destination>,
        selectedStack: NavigationStackID<Scope> = .primary,
        roots: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    ) {
        self.route = route
        self.selectedStack = selectedStack
        self.roots = roots
        self.paths = paths
    }

    /// 获取指定栈；第一次访问时创建，后续访问复用同一个对象。
    /// 仅创建栈对象不会向 roots 或 paths 中添加数据，生成的快照也不会因此改变。
    func stack(for id: NavigationStackID<Scope>) -> NavigationStackState<Destination> {
        if let existing = stacks[id] { return existing }
        let state = NavigationStackState<Destination>()
        stacks[id] = state
        return state
    }
}
