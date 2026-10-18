import Foundation
import Observation

/// 供页面操作自己所在的呈现层：打开模态、关闭当前模态、切换本层 Tab，以及处理离开确认。
///
/// App 根层和每个模态层都有自己的呈现 Context。NavigationScopeView 通过 scoped(to:)
/// 取得记录了发起栈的 Context，使未选中的 Tab 无法弹出模态；这些 Context 仍共享本层状态。
/// TabView 附件等不属于具体栈的控件，可以使用本层不指定发起栈的 Context。
/// push/pop 由页面的 NavigationContext 处理。
///
/// 这里只弱引用 Router 和所属层。即使旧页面仍持有 Context，也不会阻止它们释放。
@MainActor
@Observable
public final class NavigationPresentationContext<
    Scope: Hashable,
    Destination: Hashable,
    AlertRoute: NavigationAlertRoute
> {
    /// 这个 Context 所属的呈现层 ID。判断是否有效时，还会检查是否仍是原来的层对象。
    public let id: NavigationLayerID
    @ObservationIgnored weak var router: NavigationRouter<Scope, Destination, AlertRoute>?
    @ObservationIgnored weak var layer: NavigationLayer<Scope, Destination, AlertRoute>?
    private let sourceStack: NavigationStackID<Scope>?
    @ObservationIgnored private var stackContexts:
        [NavigationStackID<Scope>: NavigationPresentationContext<Scope, Destination, AlertRoute>] = [:]

    init(
        router: NavigationRouter<Scope, Destination, AlertRoute>,
        layer: NavigationLayer<Scope, Destination, AlertRoute>,
        sourceStack: NavigationStackID<Scope>? = nil
    ) {
        self.router = router
        self.layer = layer
        self.sourceStack = sourceStack
        id = layer.id
    }

    /// Router 是否仍在使用这个 Context 最初关联的层对象。
    /// 恢复快照会创建新的层对象，即使 UUID 相同，旧 Context 也不能操作它。
    public var isActive: Bool {
        guard let layer else { return false }
        return router?.layer(id: id) === layer
    }

    /// 这个 Context 是否属于一个仍有效的模态。
    /// App 根层始终返回 false，即使它已经打开了子模态。
    public var isPresented: Bool {
        if case .presentation = id { return isActive }
        return false
    }

    /// 这一层当前选中的栈，可绑定模态内部 TabView 的 selection。
    /// 切换时保留各栈的路径；根层只接受 scope，普通模态默认使用 primary。
    /// Context 失效、等待根模态关闭或等待用户确认时，赋值不会生效。
    /// 读取到某个栈 ID 并不代表 Context 仍然有效，需通过 isActive 判断。
    public var selectedStack: NavigationStackID<Scope> {
        get { layer?.selectedStack ?? .primary }
        set {
            guard canNavigate else { return }
            // 根层各栈需要明确的 scope 名称，不允许切换到普通模态使用的 primary 栈。
            if id == .root, newValue == .primary { return }
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

    /// 这一层是否仍有效，并且当前没有等待用户确认或根模态关闭。
    /// present 还会另行检查本层是否已有子模态。
    /// dismiss 不受此限制；用户自行关闭页面，也不会自动批准等待中的导航请求。
    var canNavigate: Bool {
        router?.canNavigate(in: layer) == true
    }

    /// 获取指定栈使用的呈现 Context。同一有效栈多次获取会返回同一个对象。
    /// 它与本层其他呈现 Context 共享状态，但只有这个栈被选中时才允许 present。
    /// NavigationScopeView 会自动把它放入页面环境。原 Context 失效后，调用此方法也不会重新连接新层。
    public func scoped(to stack: NavigationStackID<Scope>) -> NavigationPresentationContext {
        guard let router, let layer, isActive else { return self }
        let owner = router.presentationContext(in: layer)
        if let existing = owner.stackContexts[stack] { return existing }
        let context = NavigationPresentationContext(router: router, layer: layer, sourceStack: stack)
        owner.stackContexts[stack] = context
        return context
    }

    /// 获取本层指定栈的 NavigationContext，复用该栈的路径，保留当前选中的 Tab。
    /// 如果本层已失效，返回的栈 Context 也失效，无法通过它操作后来恢复的同 ID 新层。
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
    /// 并让 providesNavigationStack 返回 false，再由内容使用 NavigationScopeView 创建各 Tab 的栈。
    /// - Returns: 接受请求时返回 true，包括已排队等待的请求，不代表页面已经显示。
    @discardableResult
    public func present(
        _ destination: Destination,
        style: NavigationPresentationStyle = .sheet,
        initialStack: NavigationStackID<Scope> = .primary
    ) -> Bool {
        guard let router, isActive, let layer, layer.presentation == nil,
              !layer.isAwaitingDismissal else { return false }
        guard sourceStack == nil || sourceStack == layer.selectedStack else { return false }
        let node = NavigationPresentationNode<Scope, Destination, AlertRoute>(
            destination: destination,
            style: style,
            initialStack: initialStack
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
    /// - Returns: 找到并移除指定模态时返回 true；Context 失效或 ID 不匹配时返回 false。
    @discardableResult
    public func dismissPresented(id nodeID: UUID) -> Bool {
        guard isActive, layer?.presentation?.id == nodeID else { return false }
        if router?.hasActiveAlert == true {
            router?.dismissalsWaitingForAlert.insert(nodeID)
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
