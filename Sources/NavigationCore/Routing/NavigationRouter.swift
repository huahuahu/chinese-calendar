import Foundation
import Observation

/// 管理整个 App 的导航状态，包括根 Tab、各层模态，以及外部导航请求的执行顺序。
///
/// Scope 用来命名导航栈，通常对应 Tab；Destination 是构建页面所需的路由数据。
/// AlertRoute 是业务提示的数据，包含按钮动作的类型，但不保存 View 或业务闭包。
/// 每个呈现层保存自己的栈和子模态，页面分别通过 NavigationContext 和
/// NavigationPresentationContext 操作它们。业务数据、URL 解析和 View 创建由 App 负责。
///
/// 直接修改根栈的方法不会自动提示用户或关闭模态。
/// Deep Link、跨 Tab 等需要先处理当前模态的跳转，使用 submit。
/// 普通页面内的 push/pop 和 present/dismiss，使用环境中对应的 Context。
@MainActor
@Observable
public final class NavigationRouter<
    Scope: Hashable,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    let rootLayer: NavigationLayer<Scope, Destination, AlertRoute>
    /// 已经接受、正在等待根模态关闭后执行的请求。等待期间，以最新接受的请求为准。
    public private(set) var deferredRequest: NavigationRequest<Scope, Destination>?
    /// 等待用户确认的请求。即使模态自行关闭，这条请求仍需用户批准后才能执行。
    public internal(set) var pendingConfirmation: NavigationConfirmation<Scope, Destination>?
    /// alert 期间收到的最新导航请求，保留它原本是否要求离开确认。
    public internal(set) var requestWaitingForAlert: NavigationRequest<Scope, Destination>?
    var waitingRequestNeedsConfirmation = false
    var dismissalsWaitingForAlert: Set<UUID> = []
    var dismissAllWaitingForAlert = false
    // 缓存 Context，让页面多次获取时使用同一个对象。
    // 路径保存在各栈对象中，模态保存在所属层中。
    @ObservationIgnored var contexts: [NavigationContextID<Scope>: NavigationContext<Scope, Destination>] = [:]
    @ObservationIgnored var presentationContexts:
        [NavigationLayerID: NavigationPresentationContext<Scope, Destination, AlertRoute>] = [:]

    /// 创建 App 根层，并设置初始 Tab、根页面路由和 push 路径，此时没有模态。
    /// - Parameters:
    ///   - rootDestination: 整个根层的入口页面，不随 Tab 或路径变化。
    ///   - selectedScope: App 根界面初始选中的 Tab 或命名栈。
    ///   - rootDestinations: 各栈根页面的路由数据；由界面直接构建的静态根页可以省略。
    ///   - paths: 各栈初始已经 push 的页面列表；未提供的栈按空路径读取。
    public init(
        rootDestination: Destination,
        selectedScope: Scope,
        rootDestinations: [Scope: Destination] = [:],
        paths: [Scope: [Destination]] = [:]
    ) {
        precondition(rootDestination.supportsNavigationEntry(.root))
        precondition(rootDestinations.values.allSatisfy { $0.supportsNavigationEntry(.stackRoot) })
        precondition(paths.values.joined().allSatisfy { $0.supportsNavigationEntry(.push) })
        rootLayer = NavigationLayer(
            route: .root(destination: rootDestination),
            selectedStack: .scope(selectedScope),
            roots: rootDestination.providesNavigationContainer
                ? Dictionary(uniqueKeysWithValues: rootDestinations.map { (.scope($0.key), $0.value) })
                : [.scope(selectedScope): rootDestination],
            paths: Dictionary(uniqueKeysWithValues: paths.map { (.scope($0.key), $0.value) })
        )
    }

    /// App 根界面当前选中的 Tab 或命名栈，可绑定根 TabView 的 selection。
    /// 直接赋值只切换根 Tab，保留各栈的路径，也不会关闭模态或提示用户确认。
    public var selectedScope: Scope {
        get {
            guard case let .scope(scope) = rootLayer.selectedStack else {
                preconditionFailure("Root navigation requires an explicit scope")
            }
            return scope
        }
        set { rootLayer.selectedStack = .scope(newValue) }
    }

    /// 汇总 App 根层各栈保存的根页面路由数据，不包含模态内部的数据。
    public var rootDestinations: [Scope: Destination] {
        Dictionary(uniqueKeysWithValues: rootLayer.roots.compactMap { key, value in
            guard case let .scope(scope) = key else { return nil }
            return (scope, value)
        })
    }

    /// App 根层各栈的 push 路径。读取时汇总各栈的数据，赋值时替换整个根层的路径集合。
    /// 这是直接修改数据的入口，等待确认或关闭动画时也能写入；需要协调这些流程时使用 submit。
    public var paths: [Scope: [Destination]] {
        get {
            Dictionary(uniqueKeysWithValues: rootLayer.paths.compactMap { key, value in
                guard case let .scope(scope) = key else { return nil }
                return (scope, value)
            })
        }
        set {
            guard newValue.values.joined().allSatisfy({ $0.supportsNavigationEntry(.push) }) else { return }
            rootLayer.paths = Dictionary(uniqueKeysWithValues: newValue.map { (.scope($0.key), $0.value) })
        }
    }

    /// App 根层直接打开的模态。它还可以继续持有自己的子模态。
    public var presentedNode: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        rootLayer.presentation
    }

    /// 根层直接打开的模态为 sheet 时返回它，否则返回 nil；不查找更深层的模态。
    public var sheet: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        presentedNode?.style == .sheet ? presentedNode : nil
    }

    /// 根层直接打开的模态为全屏时返回它，否则返回 nil；不查找更深层的模态。
    public var fullScreen: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        presentedNode?.style == .fullScreen ? presentedNode : nil
    }

    /// 导航数据中是否还有页面模态或业务 alert。开始关闭时就可能变为 false，不能据此判断动画结束。
    public var hasActivePresentation: Bool {
        rootLayer.presentedContent != nil
    }

    /// 根模态已经开始关闭，但界面容器还没有通知关闭动画完成。
    /// 等待中的外部跳转需要等这个阶段结束后再执行。
    public var isAwaitingPresentationDismissal: Bool {
        rootLayer.isAwaitingDismissal
    }

    /// App 根层选中栈的最后一个 push 页面；没有 push 页面时返回它的根页面路由数据。
    /// 即使有模态覆盖，查询的仍然是根层选中的栈。
    public var selectedDestination: Destination? {
        currentDestination(on: selectedScope)
    }

    /// 读取指定根栈的根页面路由数据。静态根页可能没有保存这项数据，此时返回 nil。
    public func rootDestination(for scope: Scope) -> Destination? {
        rootLayer.stacks[.scope(scope)]?.rootDestination
    }

    /// 更新或清除指定根栈的根页面路由数据，并清空该栈的 push 路径，保留当前 Tab 选择。
    /// App 的根页面构建闭包需要读取这项数据，才能据此更新界面。
    public func setRootDestination(_ destination: Destination?, for scope: Scope) {
        guard destination?.supportsNavigationEntry(.stackRoot) != false else { return }
        let state = rootLayer.stack(for: .scope(scope))
        state.rootDestination = destination
        state.path = []
    }

    /// 读取指定根栈已经 push 的页面列表；尚未记录路径时返回空数组。
    public func path(for scope: Scope) -> [Destination] {
        rootLayer.stacks[.scope(scope)]?.path ?? []
    }

    /// 替换指定根栈的 push 路径，保留根页面路由数据、当前 Tab 选择和模态。
    public func setPath(_ path: [Destination], for scope: Scope) {
        guard path.allSatisfy({ $0.supportsNavigationEntry(.push) }) else { return }
        rootLayer.stack(for: .scope(scope)).path = path
    }

    /// 读取指定根栈最后一个 push 页面的路由数据；没有 push 页面时返回根页面路由数据。
    public func currentDestination(on scope: Scope) -> Destination? {
        path(for: scope).last ?? rootDestination(for: scope)
    }

    /// 切换到指定根 Tab，再 push 一个页面；省略 scope 时在当前根 Tab 中 push。
    /// 此方法会保留已经打开的模态。需要先确认并关闭模态时，向 submit 提交 .push 请求。
    public func push(_ destination: Destination, on scope: Scope? = nil) {
        guard destination.supportsNavigationEntry(.push) else { return }
        let targetScope = scope ?? selectedScope
        selectedScope = targetScope
        let state = rootLayer.stack(for: .scope(targetScope))
        state.path = (state.path ?? []) + [destination]
    }

    /// 从当前最上层模态继续打开 sheet；没有模态时从 App 根层打开。
    /// 本方法不返回操作结果。需要指定发起层或判断是否成功时，使用该层呈现 Context 的 present。
    public func presentSheet(_ destination: Destination) {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        context.present(destination, style: .sheet)
    }

    /// 从当前最上层模态继续打开全屏页；没有模态时从 App 根层打开。
    /// 多 Tab 页面可以指定初始选中的栈。正在等待确认或关闭时仍可能被拒绝，
    /// 需要判断是否成功时，使用该层呈现 Context 的 present。
    public func presentFullScreen(
        _ destination: Destination, initialStack: NavigationStackID<Scope> = .primary
    ) {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        context.present(destination, style: .fullScreen, initialStack: initialStack)
    }

    /// 根层直接打开的是 sheet 时，关闭它及所有子模态；其他情况不操作。
    public func dismissSheet() {
        if let sheet { rootPresentation.dismissPresented(id: sheet.id) }
    }

    /// 根层直接打开的是全屏模态时，关闭它及所有子模态；其他情况不操作。
    public func dismissFullScreen() {
        if let fullScreen { rootPresentation.dismissPresented(id: fullScreen.id) }
    }

    /// 提交一个根层导航请求，按需要依次等待用户确认、关闭模态，再执行跳转。
    ///
    /// 需要确认时，先保存 pendingConfirmation，保留当前页面和路径。
    /// 重复请求沿用提示 ID，不同请求生成新 ID，旧提示按钮无法批准新请求。
    /// 关闭动画期间收到的新请求，若要求确认，也需要单独取得用户批准。
    /// 当前有业务 alert 或正在执行它的按钮动作时，先保存最新请求，等提示处理完再评估是否确认。
    ///
    /// 请求不需要确认或已经批准时，若仍有模态或关闭动画，就保存为 deferredRequest，
    /// 先关闭根模态及其子模态，等根界面容器通知关闭完成后再跳转。
    /// 等待期间以最新接受的请求为准；没有模态和关闭动画时立即修改导航数据。
    /// - Parameters:
    ///   - request: App 已解析好的导航请求，例如切换 Tab 或替换某个栈的路径。
    ///   - confirmIfPresented: 为 true 时，只要还有模态、关闭动画或待确认请求，就先等待用户确认。
    ///     默认 false。处理外部链接通常传 true，并配置确认提示或由业务代码处理 pendingConfirmation。
    /// - Returns: 本次请求已执行，或正在等待 alert 处理完、用户确认、页面模态关闭。
    @discardableResult
    public func submit(
        _ request: NavigationRequest<Scope, Destination>,
        confirmIfPresented: Bool = false
    ) -> NavigationRequestResult {
        guard request.hasValidDestinations else { return .rejected }
        if hasBusinessAlert || (hasActiveAlert && !confirmIfPresented) {
            requestWaitingForAlert = request
            waitingRequestNeedsConfirmation = confirmIfPresented
            return .deferredUntilAlertDismisses
        }
        // 新请求取代仍未批准的旧请求；若旧请求已获批准，新请求的确认不能撤销它。
        if !confirmIfPresented || waitingRequestNeedsConfirmation {
            requestWaitingForAlert = nil
            waitingRequestNeedsConfirmation = false
        }
        let needsConfirmation = hasActivePresentation || isAwaitingPresentationDismissal ||
            pendingConfirmation != nil || hasActiveAlert
        if confirmIfPresented, needsConfirmation {
            if pendingConfirmation?.request != request {
                pendingConfirmation = NavigationConfirmation(request: request)
            }
            return .awaitingConfirmation
        }
        guard !hasActivePresentation, !isAwaitingPresentationDismissal else {
            deferredRequest = request
            rootLayer.isAwaitingDismissal = true
            dismissAllPresentations()
            return .deferredUntilPresentationDismisses
        }
        apply(request)
        return .applied
    }

    /// 根模态的关闭动画完成后，执行最后一条已接受、正在等待关闭的请求。
    ///
    /// 内置界面容器会从关闭完成回调调用此方法。自定义容器也应在实际关闭完成后调用，
    /// 不能仅凭 presentedNode 变成 nil 或固定延时判断动画结束。
    /// 没有待执行请求时，只结束关闭等待状态；重复调用不会再次执行同一请求。
    /// 尚未批准的 pendingConfirmation 继续保留。
    /// - Returns: 本次执行的请求；尚未关闭完成或没有待执行请求时返回 nil。
    @discardableResult
    public func applyDeferredRequestIfReady() -> NavigationRequest<Scope, Destination>? {
        guard isAwaitingPresentationDismissal, !hasActivePresentation else { return nil }
        let request = deferredRequest
        deferredRequest = nil
        rootLayer.isAwaitingDismissal = false
        guard let request else { return nil }
        apply(request)
        return request
    }

    /// 关闭根模态以及它继续打开的所有模态，保留根 Tab 路径和待确认请求。
    /// 这一步清空模态数据，随后仍需等待界面容器通知关闭动画完成。
    public func dismissAllPresentations() {
        if hasActiveAlert {
            dismissAllWaitingForAlert = true
            return
        }
        rootLayer.queuedPresentations.removeAll()
        rootLayer.presentation = nil
    }

    /// 当前最上层的模态。继续打开模态或选择确认提示所在层时使用；没有模态时返回 nil。
    public var frontmostPresentationNode: NavigationPresentationNode<Scope, Destination, AlertRoute>? {
        presentedNode?.frontmostPresentationNode
    }

    /// 直接按请求修改根栈数据。调用方负责在此前完成需要的用户确认和模态关闭。
    private func apply(_ request: NavigationRequest<Scope, Destination>) {
        switch request {
        case let .selectScope(scope):
            selectedScope = scope
        case let .setRoot(destination, scope):
            selectedScope = scope
            setRootDestination(destination, for: scope)
        case let .replacePath(path, scope):
            selectedScope = scope
            setPath(path, for: scope)
        case let .push(destination, scope):
            push(destination, on: scope)
        }
    }
}
