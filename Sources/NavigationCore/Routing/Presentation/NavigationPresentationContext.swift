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
/// 路由参数由层持有，旧 Context 不延长业务资源的生命周期。
@MainActor
@Observable
public final class NavigationPresentationContext<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    /// 这个 Context 所属 NavigationLayer 的 ID。判断是否有效时，还会检查是否仍是原来的层对象。
    let id: NavigationLayerID
    @ObservationIgnored weak var router: NavigationRouter<Scope, Destination, AlertRoute>?
    @ObservationIgnored weak var layer: NavigationLayer<Scope, Destination, AlertRoute>?
    private let sourceStack: NavigationStackID<Scope>?

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
    /// 即使新层使用相同 NavigationPresentationID，旧模态 Context 也不能操作它。
    var isActive: Bool {
        guard let layer else { return false }
        return router?.layer(id: id) === layer
    }

    /// 退出动画期间可读取原层入口；层释放后不保留带 Binding 的业务路由。
    var route: NavigationLayerRoute<Destination>? {
        layer?.route
    }

    var destination: Destination? {
        route?.destination
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
        set { setSelectedStack(newValue) }
    }

    /// 切换本层的选中栈，返回具体的事务或配置拒绝原因；重复选中仍表示操作已应用。
    @discardableResult
    public func setSelectedStack(_ stack: NavigationStackID<Scope>) -> NavigationMutationResult {
        guard let router, let layer else {
            return NavigationCoreLog.record(
                NavigationMutationResult.rejected(.inactiveContext), operation: "setSelectedStack", layer: id
            )
        }
        if let reason = router.navigationRejection(in: layer) {
            return NavigationCoreLog.record(
                NavigationMutationResult.rejected(reason), operation: "setSelectedStack", layer: id
            )
        }
        guard layer.route.destination.providesNavigationContainer || stack == .primary else {
            return NavigationCoreLog.record(
                NavigationMutationResult.rejected(.incompatibleContainer), operation: "setSelectedStack", layer: id
            )
        }
        guard layer.stacks[stack] != nil else {
            return NavigationCoreLog.record(
                NavigationMutationResult.rejected(.undeclaredStack), operation: "setSelectedStack", layer: id
            )
        }
        layer.selectedStack = stack
        return NavigationCoreLog.record(NavigationMutationResult.applied, operation: "setSelectedStack", layer: id)
    }

    /// 从这一层直接打开的子模态。Context 失效后返回 nil，不会继续查找更深层的模态。
    var presentedNode: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        isActive ? layer?.presentation : nil
    }

    /// 本层直接展示的内容，页面模态和业务 alert 只会有一个。
    var presentedContent: NavigationPresentation<Scope, Destination, AlertRoute>? {
        isActive ? layer?.presentedContent : nil
    }

    var presentedAlert: NavigationAlertNode<AlertRoute>? {
        isActive ? layer?.alert : nil
    }

    /// 需要由这一层处理的导航确认请求，其他层读取时返回 nil。
    ///
    /// 有模态时交给最上层模态处理；没有模态时交给根层；根模态关闭期间暂不显示。
    /// 同层多个 Tab 读到同一条请求，应由它们共用的容器提示一次。
    var confirmation: NavigationConfirmation<Scope, Destination>? {
        guard isActive, router?.confirmationLayerID == id else { return nil }
        return router?.pendingConfirmation
    }

    /// 获取指定栈使用的 NavigationPresentationContext。同一有效栈多次获取会返回同一个对象。
    /// 它与本层其他 NavigationPresentationContext 共享状态，但只有这个栈被选中时才允许 present。
    /// NavigationScopeView 会自动把它放入页面环境。原 Context 失效后，调用此方法也不会重新连接新层。
    public func scoped(to stack: NavigationStackID<Scope>) -> NavigationPresentationContext {
        guard let router, let layer else { return self }
        return router.contextStore.presentationContext(in: layer, sourceStack: stack, router: router)
    }

    /// 取得不限制发起栈的本层 NavigationPresentationContext，调用 present 时不要求某个栈被选中。
    /// 适用于 TabView 附件或同时可见的 SplitView 栏目；App 决定哪些控件可以打开模态。
    /// 已失效的 Context 不会连接到新层。
    public func unscoped() -> NavigationPresentationContext {
        guard let router, let layer else { return self }
        return router.presentationContext(in: layer)
    }

    /// 获取本层指定栈的 NavigationContext，复用该栈的状态，不改变当前选中的栈。
    /// 退出动画可以读取原层的栈，但命令仍拒绝；不会创建栈或连接同 ID 新层。
    public func context(for stack: NavigationStackID<Scope>) -> NavigationContext<Scope, Destination> {
        // 保留失效状态，避免旧页面通过相同 ID 找到新栈。
        guard let layer else {
            return NavigationContext(id: stack, state: nil, access: .inactive, layerID: id)
        }
        guard let router else {
            return NavigationContext(id: stack, state: layer.stacks[stack], access: .inactive, layerID: id)
        }
        return router.context(in: layer, stack: stack)
    }

    /// 从当前层打开一个模态，页面内容由 destination 路由数据构建。
    ///
    /// 如果 Context 指定了发起栈，只允许当前选中的栈打开模态。
    /// 本层已有页面模态或该页面还在关闭时返回具体拒绝原因；已有 alert 时保存请求，等提示处理完再展示。
    /// 普通模态使用默认的 initialStack；多 Tab 模态应指定初始 Tab 的 scope，
    /// 并让 providesNavigationContainer 返回 true，再由内容使用 NavigationScopeView 创建各 Tab 的栈。
    /// - Returns: applied 表示已写入呈现数据，queued 表示已排队；均不代表页面显示动画完成。
    @discardableResult
    func submitPresentation(
        _ destination: Destination,
        style: NavigationPresentationStyle = .sheet,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:],
        lifetime: NavigationPresentationLifetime = NavigationPresentationLifetime()
    ) -> NavigationPresentationResult {
        performSubmission(operation: "present") { router, layer in
            if let reason = presentationRejection(in: layer) { return .rejected(reason) }
            guard let presentedLayer = NavigationLayer<Scope, Destination, AlertRoute>(
                route: .presentation(id: NavigationPresentationID(), destination: destination),
                initialStack: initialStack, rootDestinations: rootDestinations, paths: paths
            ) else {
                let reason = NavigationLayer<Scope, Destination, AlertRoute>.validationRejection(
                    destination: destination, initialStack: initialStack, rootDestinations: rootDestinations,
                    paths: paths
                ) ?? .incompatibleContainer
                return .rejected(reason)
            }
            let node = NavigationPresentationNode(style: style, layer: presentedLayer, lifetime: lifetime)
            return router.enqueue(.page(node), in: layer)
        }
    }

    /// 根据业务路由提交 alert。当前已有 alert 时排队，不替换用户尚未回答的提示。
    @discardableResult
    func submitAlert(
        _ destination: AlertRoute,
        lifetime: NavigationPresentationLifetime = NavigationPresentationLifetime()
    ) -> NavigationPresentationResult {
        performSubmission(operation: "presentAlert") { router, layer in
            guard sourceStack == nil || sourceStack == layer.selectedStack else {
                return .rejected(.sourceStackNotSelected)
            }
            return router.enqueue(
                .alert(NavigationAlertNode(destination: destination, lifetime: lifetime)),
                in: layer
            )
        }
    }

    /// 只在这里记录提交的最终决策；拒绝请求由宿主回滚资源，不发送已接受请求的完成通知。
    private func performSubmission(
        operation: String,
        submission: (
            NavigationRouter<Scope, Destination, AlertRoute>, NavigationLayer<Scope, Destination, AlertRoute>
        ) -> NavigationPresentationResult
    ) -> NavigationPresentationResult {
        guard let router else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.rejected(.inactiveContext), operation: operation, layer: id
            )
        }
        let result: NavigationPresentationResult = if isActive, let layer {
            submission(router, layer)
        } else {
            .rejected(.inactiveContext)
        }
        return NavigationCoreLog.record(result, operation: operation, layer: id)
    }

    /// 关闭当前所在的模态，以及从它继续打开的所有子模态，保留父层各栈的路径。
    /// 根层返回 noChange(.notPresented)，失效 Context 返回拒绝原因；关闭本层的子模态使用 dismissPresented。
    @discardableResult
    public func dismiss() -> NavigationPresentationResult {
        guard isActive, let router else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.rejected(.inactiveContext), operation: "dismiss", layer: id
            )
        }
        guard case let .presentation(nodeID) = id else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.noChange(.notPresented), operation: "dismiss", layer: id
            )
        }
        return router.dismissPresentation(id: nodeID)
    }

    /// 关闭本层直接打开的指定子模态，也会关闭它继续打开的模态。下滑关闭也使用这个方法。
    ///
    /// 只有 ID 与当前子模态一致时才关闭，避免旧页面的延迟回调误关新页面。
    /// 清空模态数据后，仍需等待界面容器的 onDismiss 通知，才允许这一层再次 present。
    /// - Returns: applied 表示已移除模态数据；有活动 alert 时返回 queued，等待它及业务动作完成。
    ///   失效 Context 返回拒绝原因，ID 不匹配返回 noChange(.presentationNotFound)。
    @discardableResult
    func dismissPresented(id nodeID: NavigationPresentationID) -> NavigationPresentationResult {
        guard isActive, let router, let layer else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.rejected(.inactiveContext), operation: "dismissPresented", layer: id
            )
        }
        guard let node = layer.presentation, node.id == nodeID else {
            return NavigationCoreLog.record(
                NavigationPresentationResult.noChange(.presentationNotFound), operation: "dismissPresented", layer: id
            )
        }
        return router.dismiss(lifetime: node.lifetime)
    }

    /// 同意执行指定导航请求。有模态时，根 Router 会先关闭模态，等关闭完成后再跳转。
    /// 传入 confirmation 中的请求 ID；返回拒绝或过期原因，接受后仍可能等待关闭。
    @discardableResult
    func confirmNavigation(id: NavigationConfirmationID) -> NavigationRequestResult {
        guard isActive, let router else {
            return NavigationCoreLog.record(
                NavigationRequestResult.rejected(.inactiveContext), operation: "confirmNavigation", layer: self.id
            )
        }
        return router.confirmNavigation(id: id)
    }

    /// 取消指定导航请求，保留当前页面和路径。过期 ID 不会取消后来收到的新请求。
    @discardableResult
    func cancelNavigation(id: NavigationConfirmationID) -> NavigationMutationResult {
        guard isActive, let router else {
            return NavigationCoreLog.record(
                NavigationMutationResult.rejected(.inactiveContext), operation: "cancelNavigation", layer: self.id
            )
        }
        return router.cancelConfirmation(id: id)
    }

    func context(
        for node: NavigationPresentationNode<Scope, Destination, AlertRoute>
    ) -> NavigationPresentationContext<Scope, Destination, AlertRoute>? {
        router?.presentationContext(for: node)
    }

    /// 由本层的界面容器通知：它打开的子模态已经完成关闭动画。
    /// 子模态关闭后，本层可以再次 present；只有根层收到通知时，才会执行等待中的全局跳转。
    func presentationDidDismiss(lifetime: NavigationPresentationLifetime) {
        guard let router, let layer else {
            lifetime.finish()
            return
        }
        router.completePresentationDismissal(in: layer, lifetime: lifetime)
    }

    /// 保留给未传入 lifetime 的内部调用，从当前 layer 查找正在关闭的 presentation。
    /// SwiftUI 的关闭回调直接传入本次 lifetime，避免迟到回调结束后来创建的 presentation。
    func presentationDidDismiss() {
        guard let lifetime = layer?.dismissingPresentation?.lifetime else { return }
        presentationDidDismiss(lifetime: lifetime)
    }

    private func presentationRejection(
        in layer: NavigationLayer<Scope, Destination, AlertRoute>
    ) -> NavigationRejectionReason? {
        guard layer.presentation == nil else { return .presentationAlreadyExists }
        guard !layer.isAwaitingDismissal else { return .awaitingDismissal }
        guard sourceStack == nil || sourceStack == layer.selectedStack else { return .sourceStackNotSelected }
        return nil
    }
}
