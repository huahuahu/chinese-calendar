import Observation

/// 供页面操作自己所在的导航栈，提供 path、push 和 pop。
///
/// 一个栈的栈底页面及其 push 页面共享同一个 Context；不同栈使用不同的 Context。
/// 路径直接保存在 NavigationStackState 中，这里根据传入的规则判断是否还能访问和修改。
/// 打开或关闭模态时，页面单独读取环境中的 NavigationPresentationContext。
///
/// 通过 Router 或 NavigationPresentationContext 获取实例，再由 NavigationScopeView 放入页面环境。
/// 跨 Tab 跳转或需要先关闭模态的 Deep Link 请求，交给根 Router 处理。
@MainActor
@Observable
public final class NavigationContext<Scope: NavigationScope, Destination: NavigationDestination> {
    /// 这个栈在所属 NavigationLayer 中的 ID。其他层可以使用相同 ID，它们的路径互不影响。
    public let id: NavigationStackID<Scope>
    @ObservationIgnored private(set) weak var state: NavigationStackState<Destination>?
    private let access: NavigationStackAccess
    /// 只保存诊断身份，不保留层对象；独立构造的栈可以没有所属层。
    private let layerID: NavigationLayerID?

    init(
        id: NavigationStackID<Scope>,
        state: NavigationStackState<Destination>?,
        access: NavigationStackAccess,
        layerID: NavigationLayerID? = nil
    ) {
        self.id = id
        self.state = state
        self.access = access
        self.layerID = layerID
    }

    /// 这个 Context 是否仍可访问原来的栈。未选中的 Tab 也可以有效。
    /// 具体规则由创建方提供；原栈失效后，出现相同 ID 的新栈也不会让它重新生效。
    public var isActive: Bool {
        state != nil && access.isActive()
    }

    private var mutationRejection: NavigationRejectionReason? {
        if let reason = access.rejectionReason() { return reason }
        return isActive ? nil : .inactiveContext
    }

    /// 当前导航栈的栈底页面 Destination，不包含之后 push 的页面。
    /// 例如 .tabs 层中的首页栈可以从 .home 开始。
    /// 每个有效栈都有根 Destination；未声明或已经失效的 Context 返回 nil。
    public var rootDestination: Destination? {
        isActive ? state?.rootDestination : nil
    }

    /// 替换本栈的栈底页面并清空 push 路径，不改变打开整层时的 Destination 或其他栈。
    @discardableResult
    public func setRootDestination(_ destination: Destination) -> NavigationMutationResult {
        if let reason = mutationRejection { return record(.rejected(reason), operation: "setRootDestination") }
        state?.rootDestination = destination
        state?.path = []
        return record(.applied, operation: "setRootDestination")
    }

    /// 这个栈中已经 push 的页面列表，不包含栈底页面。
    ///
    /// NavigationStack 绑定此属性后，返回手势、NavigationLink(value:) 和代码中的 push/pop
    /// 都会读写同一份路径。Context 失效时读到空数组；不允许修改时忽略赋值。
    public var path: [Destination] {
        get { isActive ? state?.path ?? [] : [] }
        set { setPath(newValue) }
    }

    /// 替换本栈的 push 路径。需要同步更新业务选择时，调用方应先确认路径修改成功。
    /// 重复设置相同路径仍返回 applied；拒绝时返回原因，并保持路径不变。
    @discardableResult
    public func setPath(_ newPath: [Destination]) -> NavigationMutationResult {
        if let reason = mutationRejection { return record(.rejected(reason), operation: "setPath") }
        state?.path = newPath
        return record(.applied, operation: "setPath")
    }

    /// 在本栈中 push 一个页面，不切换所在层选中的栈，也不改变其他栈的路径。
    /// - Returns: 已应用或具体拒绝原因；拒绝时不修改路径。
    @discardableResult
    public func push(_ destination: Destination) -> NavigationMutationResult {
        if let reason = mutationRejection { return record(.rejected(reason), operation: "push") }
        state?.path.append(destination)
        return record(.applied, operation: "push")
    }

    /// 返回本栈的上一页。已在栈底页面时不执行操作，也不会关闭所在模态。
    /// - Returns: 已应用、已经在栈底，或具体拒绝原因。
    @discardableResult
    public func pop() -> NavigationMutationResult {
        if let reason = mutationRejection { return record(.rejected(reason), operation: "pop") }
        guard state?.path.isEmpty == false else { return record(.noChange(.alreadyAtRoot), operation: "pop") }
        state?.path.removeLast()
        return record(.applied, operation: "pop")
    }

    private func record(_ result: NavigationMutationResult, operation: String) -> NavigationMutationResult {
        NavigationCoreLog.record(result, operation: operation, layer: layerID, stack: String(describing: id))
    }
}
