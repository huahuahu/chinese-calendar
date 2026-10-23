import Observation

/// 保存 App 根界面或一个模态页面的导航状态；它们各自拥有独立的 NavigationLayer。
///
/// 一层可以包含多个导航栈，例如多个 Tab，但同一时刻只能直接展示一个页面模态或业务 alert。
/// 页面模态有自己的层，可以继续打开下一层；alert 没有下一层，后续提示先排队。
/// Router 和模态节点持有这些状态，页面通过对应的 Context 操作它们。
@MainActor
@Observable
final class NavigationLayer<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    @ObservationIgnored weak var presentationEndpoint: NavigationPresentationEndpoint<Scope, Destination, AlertRoute>?

    let routeState: NavigationLayerRouteState<Destination>

    var route: NavigationLayerRoute<Destination> {
        routeState.route
    }

    var id: NavigationLayerID {
        route.id
    }

    /// 当前选中的导航栈。切换 Tab 时，其他栈已经 push 的页面会保留。
    var selectedStack: NavigationStackID<Scope>
    /// 当前 NavigationLayer 拥有的导航栈；每个栈分别保存栈底页面的 Destination 和 push 路径。
    private(set) var stacks: [NavigationStackID<Scope>: NavigationStackState<Destination>] = [:]

    /// 汇总已声明栈的栈底页面；不另存一份根路由字典。
    var roots: [NavigationStackID<Scope>: Destination] {
        stacks.mapValues(\.rootDestination)
    }

    /// 读取时汇总各栈的 push 路径，赋值时更新各栈中保存的路径。
    /// 整体替换时保留原来的栈对象，让页面已持有的 Context 继续读写它们。
    var paths: [NavigationStackID<Scope>: [Destination]] {
        get { stacks.mapValues(\.path).filter { !$0.value.isEmpty } }
        set {
            // 路径不能隐式创建无根栈；非法整批替换保持原状态。
            guard newValue.keys.allSatisfy({ stacks[$0] != nil }) else { return }
            for (id, state) in stacks {
                state.path = newValue[id] ?? []
            }
        }
    }

    /// 页面模态和业务 alert 共用这一份呈现状态。
    var presentedContent: NavigationPresentation<Scope, Destination, AlertRoute>?
    /// 已接受但暂不能展示的页面模态或业务提示；允许继续呈现时按入队顺序处理。
    var queuedPresentations: [NavigationPresentation<Scope, Destination, AlertRoute>] = []
    /// 系统已开始展示或正在关闭的 alert；业务动作处理完成后才释放这次会话。
    var alertSession: NavigationAlertSession?
    /// 已从活动树移除、但界面仍在关闭的子树。真实关闭完成后释放，保留动画所需的会话身份。
    var dismissingPresentation: NavigationPresentationNode<Scope, Destination, AlertRoute>?

    var presentation: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        get {
            guard case let .page(node) = presentedContent else { return nil }
            return node
        }
        set {
            if let presentation, newValue == nil {
                dismissingPresentation = presentation
                isAwaitingDismissal = true
            }
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

    /// 根层与新模态共用初始化规则，完整校验后才创建栈状态。
    /// 页面自带容器时必须声明选中栈和所有路径对应的根；Core 单栈只接受 primary。
    init?(
        route: NavigationLayerRoute<Destination>,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    ) {
        guard Self.validationRejection(
            destination: route.destination, initialStack: initialStack,
            rootDestinations: rootDestinations, paths: paths
        ) == nil else { return nil }
        let roots: [NavigationStackID<Scope>: Destination] = route.destination.providesNavigationContainer
            ? rootDestinations : [.primary: route.destination]
        routeState = NavigationLayerRouteState(route: route)
        selectedStack = initialStack
        stacks = Dictionary(uniqueKeysWithValues: roots.map { id, root in
            (id, NavigationStackState(rootDestination: root, path: paths[id] ?? []))
        })
    }

    /// 与初始化共用校验规则，让呈现入口返回具体拒绝原因而不复制容器约束。
    static func validationRejection(
        destination: Destination,
        initialStack: NavigationStackID<Scope>,
        rootDestinations: [NavigationStackID<Scope>: Destination],
        paths: [NavigationStackID<Scope>: [Destination]]
    ) -> NavigationRejectionReason? {
        if destination.providesNavigationContainer {
            guard rootDestinations[initialStack] != nil,
                  paths.keys.allSatisfy({ rootDestinations[$0] != nil }) else { return .missingRootDestination }
        } else {
            guard initialStack == .primary, rootDestinations.isEmpty,
                  paths.keys.allSatisfy({ $0 == .primary }) else { return .incompatibleContainer }
        }
        return nil
    }

    /// 显式声明或替换栈根，并清空旧路径；仅获取 Context 不会创建栈。
    func setRoot(_ destination: Destination, for id: NavigationStackID<Scope>) {
        if let state = stacks[id] {
            state.rootDestination = destination
            state.path = []
        } else {
            stacks[id] = NavigationStackState(rootDestination: destination)
        }
    }
}
