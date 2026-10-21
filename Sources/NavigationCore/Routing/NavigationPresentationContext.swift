import Foundation
import Observation

/// 供页面操作自己所在的 NavigationLayer：打开模态、关闭当前模态、切换本层 Tab，以及处理离开确认。
///
/// 同一个 NavigationLayer 可以对应多个 NavigationPresentationContext。例如一个只使用 3 个固定 Tab 栈的层，
/// 最多有 4 个实例：1 个不指定发起栈的层级 Context，以及每个 Tab 各 1 个 scoped Context。
/// 这些实例按需创建并缓存，全部属于同一层，共享入口路由、选中栈、模态呈现和离开确认状态。
/// scoped Context 额外记录 sourceStack，用于限制未选中 Tab 发起模态；它不会创建新的导航层。
/// 普通单栈使用默认宿主配置时，也有 1 个层级 Context 和 1 个 .primary scoped Context。
///
/// NavigationScopeView 通过 scoped(to:) 取得对应栈的呈现入口；TabView 附件等公共控件
/// 使用不指定发起栈的层级 Context。各 Tab 的 path 和 push/pop 由各自的 NavigationContext 管理。
/// App 根界面拥有根层；每次打开 sheet／full-screen 才会创建下一层及其自己的 NavigationPresentationContext。
///
/// 这里只弱引用 Router 和所属层。即使旧页面仍持有 Context，也不会阻止它们释放。
/// 独立保留共享的入口记录，让路由读取不依赖层是否仍有效。
@MainActor
@Observable
public final class NavigationPresentationContext<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    /// 这个 Context 所属 NavigationLayer 的 ID。判断是否有效时，还会检查是否仍是原来的层对象。
    public let id: NavigationLayerID
    @ObservationIgnored weak var router: NavigationRouter<Scope, Destination, AlertRoute>?
    @ObservationIgnored weak var layer: NavigationLayer<Scope, Destination, AlertRoute>?
    private let routeState: NavigationLayerRouteState<Destination>
    private let sourceStack: NavigationStackID<Scope>?
    /// 仅由本层不指定sourceStack的层级 Context 保存和使用的缓存；各 scoped Context 的字典始终为空。
    /// 层级 Context 初始化时缓存也为空，首次 scoped(to:) 后才写入对应条目。
    /// 普通单栈的默认宿主会缓存 .primary 对应的 scoped Context；Tab 层按需缓存各 Tab 的入口。
    /// 即使从 scoped Context 再调用 scoped(to:)，也会回到本层层级 Context 查找或写入。
    /// 显式关闭宿主的发起栈限制时使用 unscoped()，该调用不会填充此缓存。
    @ObservationIgnored private var stackContexts:
        [NavigationStackID<Scope>: NavigationPresentationContext<Scope, Destination, AlertRoute>] = [:]

    init(
        router: NavigationRouter<Scope, Destination, AlertRoute>,
        layer: NavigationLayer<Scope, Destination, AlertRoute>,
        sourceStack: NavigationStackID<Scope>? = nil
    ) {
        self.router = router
        self.layer = layer
        routeState = layer.routeState
        self.sourceStack = sourceStack
        id = layer.id
    }

    /// Router 是否仍在使用这个 Context 最初关联的层对象。
    /// 恢复快照会为模态创建新的层对象，即使 UUID 相同，旧模态 Context 也不能操作它。
    public var isActive: Bool {
        guard let layer else { return false }
        return router?.layer(id: id) === layer
    }

    /// 构建整个根界面或打开当前模态时使用的路由，与所属层共享同一份记录。
    /// Context 失效或层释放后仍可读取；是否允许操作和渲染由 isActive 单独判断。
    /// 根快照恢复更新这份记录；模态中的 push 不改变其入口。
    public var route: NavigationLayerRoute<Destination> {
        routeState.route
    }

    /// 所关联层的入口页面；失效后保留原层最后的入口，不连接同 ID 的新层。
    public var destination: Destination {
        route.destination
    }

    /// 这个 Context 是否属于一个仍有效的模态。
    /// App 根层始终返回 false，即使它已经打开了子模态。
    public var isPresented: Bool {
        if case .presentation = id { return isActive }
        return false
    }

    /// 这一层当前选中的栈，可绑定根界面或模态内 TabView 的 selection。
    /// 切换时保留各栈的路径；由 Core 自动提供 NavigationStack 的层只使用 primary。
    /// Context 失效、等待根模态关闭、等待用户确认或仍有活动 alert 时，赋值不会生效。
    /// 读取到某个栈 ID 并不代表 Context 仍然有效，需通过 isActive 判断。
    public var selectedStack: NavigationStackID<Scope> {
        get { layer?.selectedStack ?? .primary }
        set {
            guard canNavigate, layer?.stacks[newValue] != nil else { return }
            // Core 提供的单栈只承载 primary，根层与模态层使用同一规则。
            if layer?.route.destination.providesNavigationContainer == false, newValue != .primary { return }
            layer?.selectedStack = newValue
        }
    }

    /// 从这一层直接打开的子模态。Context 失效后返回 nil，不会继续查找更深层的模态。
    public var presentedNode: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        isActive ? layer?.presentation : nil
    }

    /// 本层直接展示的内容，页面模态和业务 alert 只会有一个。
    public var presentedContent: NavigationPresentation<Scope, Destination, AlertRoute>? {
        isActive ? layer?.presentedContent : nil
    }

    public var presentedAlert: NavigationAlertNode<AlertRoute>? {
        isActive ? layer?.alert : nil
    }

    /// 需要由这一层处理的导航确认请求，其他层读取时返回 nil。
    ///
    /// 有模态时交给最上层模态处理；没有模态时交给根层；根模态关闭期间暂不显示。
    /// 同层多个 Tab 读到同一条请求，应由它们共用的容器提示一次。
    public var confirmation: NavigationConfirmation<Scope, Destination>? {
        guard isActive, router?.confirmationLayerID == id else { return nil }
        return router?.pendingConfirmation
    }

    /// 这一层是否仍有效，且没有待确认请求、根模态关闭等待或活动 alert。
    /// 选中栈等需要立即修改状态的操作使用此判断；present／dismiss 另行检查并处理排队。
    var canNavigate: Bool {
        router?.canNavigate(in: layer) == true
    }

    /// 获取指定栈使用的 NavigationPresentationContext。同一有效栈多次获取会返回同一个对象。
    /// 它与本层其他 NavigationPresentationContext 共享状态，但只有这个栈被选中时才允许 present。
    /// NavigationScopeView 会自动把它放入页面环境。原 Context 失效后，调用此方法也不会重新连接新层。
    public func scoped(to stack: NavigationStackID<Scope>) -> NavigationPresentationContext {
        guard let router, let layer, isActive else { return self }
        let owner = router.presentationContext(in: layer)
        if let existing = owner.stackContexts[stack] { return existing }
        let context = NavigationPresentationContext(router: router, layer: layer, sourceStack: stack)
        owner.stackContexts[stack] = context
        return context
    }

    /// 取得不限制发起栈的本层 NavigationPresentationContext，调用 present 时不要求某个栈被选中。
    /// 适用于 TabView 附件或同时可见的 SplitView 栏目；App 决定哪些控件可以打开模态。
    /// 已失效的 Context 不会连接到新层。
    public func unscoped() -> NavigationPresentationContext {
        guard let router, let layer, isActive else { return self }
        return router.presentationContext(in: layer)
    }

    /// 获取本层指定栈的 NavigationContext，复用该栈的状态，不改变当前选中的栈。
    /// 未声明根的栈或已失效的层返回失效 Context，不会创建栈或连接后来恢复的同 ID 新层。
    public func context(for stack: NavigationStackID<Scope>) -> NavigationContext<Scope, Destination> {
        // 保留失效状态，避免旧页面通过相同 ID 找到恢复后的新栈。
        guard let router, let layer, isActive else {
            return NavigationContext(id: stack, state: nil, access: .inactive)
        }
        return router.context(in: layer, stack: stack)
    }

    /// 从当前层打开一个模态，页面内容由 destination 路由数据构建。
    ///
    /// 如果 Context 指定了发起栈，只允许当前选中的栈打开模态。
    /// 本层已有页面模态或该页面还在关闭时返回 false；已有 alert 时保存请求，等提示处理完再展示。
    /// 普通模态使用默认的 initialStack；多 Tab 模态应指定初始 Tab 的 scope，
    /// 并让 providesNavigationContainer 返回 true，再由内容使用 NavigationScopeView 创建各 Tab 的栈。
    /// - Returns: 接受请求时返回 true，包括已排队等待的请求，不代表页面已经显示。
    @discardableResult
    public func present(
        _ destination: Destination,
        style: NavigationPresentationStyle = .sheet,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    ) -> Bool {
        guard NavigationLayerSnapshot<Scope, Destination, AlertRoute>(
            destination: destination, initialStack: initialStack,
            rootDestinations: rootDestinations, paths: paths
        ) != nil else { return false }
        guard let router, isActive, let layer, layer.presentation == nil,
              !layer.isAwaitingDismissal else { return false }
        guard sourceStack == nil || sourceStack == layer.selectedStack else { return false }
        let node = NavigationPresentationNode<Scope, Destination, AlertRoute>(
            destination: destination,
            style: style,
            initialStack: initialStack, rootDestinations: rootDestinations, paths: paths
        )
        return router.enqueue(.page(node), in: layer)
    }

    /// 根据业务路由展示 alert。当前已有 alert 时排队，不替换用户尚未回答的提示。
    @discardableResult
    public func presentAlert(_ destination: AlertRoute) -> Bool {
        guard let router, let layer, isActive else { return false }
        guard sourceStack == nil || sourceStack == layer.selectedStack else { return false }
        return router.enqueue(.alert(NavigationAlertNode(destination: destination)), in: layer)
    }

    /// 关闭当前所在的模态，以及从它继续打开的所有子模态，保留父层各栈的路径。
    /// 根层或已失效的 Context 返回 false。要关闭本层打开的子模态，使用 dismissPresented。
    @discardableResult
    public func dismiss() -> Bool {
        guard isActive, case let .presentation(nodeID) = id else { return false }
        return router?.dismissPresentation(id: nodeID) ?? false
    }

    /// 关闭本层直接打开的指定子模态，也会关闭它继续打开的模态。下滑关闭也使用这个方法。
    ///
    /// 只有 ID 与当前子模态一致时才关闭，避免旧页面的延迟回调误关新页面。
    /// 清空模态数据后，仍需等待界面容器的 onDismiss 通知，才允许这一层再次 present。
    /// - Returns: 接受关闭请求时返回 true；有活动 alert 时先等待它结束，不会立即移除模态。
    ///   Context 失效或 ID 不匹配时返回 false。
    @discardableResult
    public func dismissPresented(id nodeID: UUID) -> Bool {
        guard isActive, layer?.presentation?.id == nodeID else { return false }
        if router?.hasActiveAlert == true {
            router?.coordinationState.deferDismissalUntilAlertEnds(id: nodeID)
            return true
        }
        layer?.presentation = nil
        return true
    }

    /// 同意执行指定导航请求。有模态时，根 Router 会先关闭模态，等关闭完成后再跳转。
    /// 传入 confirmation 中的请求 ID；Context 失效或请求已被替换时，调用不会生效。
    public func confirmNavigation(id: UUID) {
        guard isActive else { return }
        router?.confirmNavigation(id: id)
    }

    /// 取消指定导航请求，保留当前页面和路径。过期 ID 不会取消后来收到的新请求。
    public func cancelNavigation(id: UUID) {
        guard isActive else { return }
        router?.cancelConfirmation(id: id)
    }

    func context(
        for node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    ) -> NavigationPresentationContext<Scope, Destination, AlertRoute>? {
        router?.presentationContext(for: node)
    }

    /// 由本层的界面容器通知：它打开的子模态已经完成关闭动画。
    /// 子模态关闭后，本层可以再次 present；只有根层收到通知时，才会执行等待中的全局跳转。
    func presentationDidDismiss() {
        guard isActive else { return }
        if id != .root { layer?.isAwaitingDismissal = false }
        router?.presentationDidDismiss(isRoot: id == .root)
        router?.resumePresentations()
    }
}
