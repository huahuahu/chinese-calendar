import Foundation
import Observation

/// 管理一棵导航树的状态，包括 App 根层的各栈、逐层打开的模态，以及外部导航请求的执行顺序。
///
/// Scope 用来命名导航栈，通常对应 Tab；Destination 是构建页面所需的路由数据。
/// AlertRoute 是业务提示的数据，包含按钮动作的类型，但不保存 View 或业务闭包。
/// 每个 NavigationLayer 保存自己的栈和子模态，页面分别通过 NavigationContext 和
/// NavigationPresentationContext 操作它们。业务数据、URL 解析和 View 创建由 App 负责。
///
/// 直接修改根栈的方法不会自动提示用户或关闭模态。
/// Deep Link、跨 Tab 等需要先处理当前模态的跳转，使用 submit。
/// 普通页面内的 push/pop 和 present/dismiss，使用环境中对应的 Context。
@MainActor
@Observable
public final class NavigationRouter<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    let rootLayer: NavigationLayer<Scope, Destination, AlertRoute>
    var coordinationState = NavigationCoordinationState<Scope, Destination>()
    /// 已经接受、正在等待根模态关闭后执行的请求。等待期间，以最新接受的请求为准。
    public var deferredRequest: NavigationRequest<Scope, Destination>? {
        coordinationState.deferredRequest
    }

    /// 等待用户确认的请求。即使模态自行关闭，这条请求仍需用户批准后才能执行。
    public var pendingConfirmation: NavigationConfirmation<Scope, Destination>? {
        coordinationState.pendingConfirmation
    }

    /// alert 期间收到的最新导航请求，保留它原本是否要求离开确认。
    public var requestWaitingForAlert: NavigationRequest<Scope, Destination>? {
        coordinationState.requestWaitingForAlert
    }

    // 缓存 Context，让页面多次获取时使用同一个对象。
    // 路径保存在各栈对象中，模态保存在所属层中。
    @ObservationIgnored var contexts: [NavigationContextID<Scope>: NavigationContext<Scope, Destination>] = [:]
    @ObservationIgnored var presentationContexts:
        [NavigationLayerID: NavigationPresentationContext<Scope, Destination, AlertRoute>] = [:]

    /// 创建 App 根层。Core 自动提供 NavigationStack 时使用 primary 栈；
    /// 页面自带 TabView／SplitView 等容器时，由 App 指定各栈及初始选择。
    /// 根层与 present 创建的模态层采用相同的初始化规则。
    public init(
        rootDestination: Destination,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    ) {
        guard let snapshot = NavigationLayerSnapshot<Scope, Destination, AlertRoute>(
            destination: rootDestination, initialStack: initialStack,
            rootDestinations: rootDestinations, paths: paths
        ) else { preconditionFailure("Every selected or routed navigation stack requires a root Destination") }
        rootLayer = NavigationLayer(route: .root(destination: rootDestination), snapshot: snapshot)
    }

    /// 自带命名栈容器的便利入口；普通单栈使用 initialStack 的默认 primary。
    public convenience init(
        rootDestination: Destination,
        selectedScope: Scope,
        rootDestinations: [Scope: Destination] = [:],
        paths: [Scope: [Destination]] = [:]
    ) {
        self.init(
            rootDestination: rootDestination, initialStack: .scope(selectedScope),
            rootDestinations: Dictionary(uniqueKeysWithValues: rootDestinations.map { (.scope($0.key), $0.value) }),
            paths: Dictionary(uniqueKeysWithValues: paths.map { (.scope($0.key), $0.value) })
        )
    }

    /// 根层当前选中命名栈的 scope；选中 primary 时返回 nil。
    /// 写入非 nil 值只切换命名栈，保留路径和模态；写入 nil 不改变选择。
    /// 完整栈身份及 primary 的切换使用 rootPresentation.selectedStack。
    public var selectedScope: Scope? {
        get {
            guard case let .scope(scope) = rootLayer.selectedStack else { return nil }
            return scope
        }
        set {
            guard let newValue, rootLayer.route.destination.providesNavigationContainer,
                  rootLayer.stacks[.scope(newValue)] != nil else { return }
            rootLayer.selectedStack = .scope(newValue)
        }
    }

    /// 汇总 App 根层各命名栈的栈底页面 Destination，不包含 primary 栈或模态内部的数据。
    public var rootDestinations: [Scope: Destination] {
        Dictionary(uniqueKeysWithValues: rootLayer.roots.compactMap { key, value in
            guard case let .scope(scope) = key else { return nil }
            return (scope, value)
        })
    }

    /// 读取 App 根层各命名栈的 push 路径，不包含 primary 栈。
    /// 页面自带容器时，赋值会替换根层的完整路径集合，连同未列出的栈路径一起清除；
    /// Core 自动提供单栈时忽略赋值，操作 primary 路径应使用 rootPresentation.context(for: .primary)。
    /// 这是直接修改数据的入口，等待确认或关闭动画时也能写入；需要协调这些流程时使用 submit。
    public var paths: [Scope: [Destination]] {
        get {
            Dictionary(uniqueKeysWithValues: rootLayer.paths.compactMap { key, value in
                guard case let .scope(scope) = key else { return nil }
                return (scope, value)
            })
        }
        set {
            guard rootLayer.route.destination.providesNavigationContainer else { return }
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

    /// App 根层直接打开的模态已经开始关闭，但界面容器还没有通知关闭动画完成。
    /// 等待中的外部跳转需要等这个阶段结束后再执行。
    public var isAwaitingPresentationDismissal: Bool {
        rootLayer.isAwaitingDismissal
    }

    /// App 根层选中栈的最后一个 push 页面；没有 push 页面时返回它记录的栈底页面 Destination。
    /// 即使有模态覆盖，查询的仍然是根层选中的栈。
    public var selectedDestination: Destination? {
        let state = rootLayer.stacks[rootLayer.selectedStack]
        return state?.path.last ?? state?.rootDestination
    }

    /// 读取 App 根层指定命名栈的栈底页面 Destination。
    /// 未声明该栈时返回 nil。
    public func rootDestination(for scope: Scope) -> Destination? {
        rootLayer.stacks[.scope(scope)]?.rootDestination
    }

    /// 声明或替换 App 根层指定命名栈的栈底页面，并清空该栈的 push 路径。
    /// 不切换选中的栈；空详情使用明确的空态 Destination。
    public func setRootDestination(_ destination: Destination, for scope: Scope) {
        guard rootLayer.route.destination.providesNavigationContainer else { return }
        rootLayer.setRoot(destination, for: .scope(scope))
    }

    /// 读取 App 根层指定命名栈已经 push 的页面列表；尚未记录路径时返回空数组。
    public func path(for scope: Scope) -> [Destination] {
        rootLayer.stacks[.scope(scope)]?.path ?? []
    }

    /// 替换 App 根层指定命名栈的 push 路径，保留栈底页面、选中的栈和模态。
    public func setPath(_ path: [Destination], for scope: Scope) {
        guard rootLayer.route.destination.providesNavigationContainer else { return }
        rootLayer.stacks[.scope(scope)]?.path = path
    }

    /// 读取 App 根层指定命名栈的最后一个 push 页面；没有 push 页面时返回其栈底页面 Destination。
    public func currentDestination(on scope: Scope) -> Destination? {
        path(for: scope).last ?? rootDestination(for: scope)
    }

    /// 选中 App 根层的指定命名栈，再 push 一个页面；省略 scope 时在根层当前选中的栈中 push。
    /// 当前选中的是 primary 栈时也可省略 scope，不要求根界面使用 TabView。
    /// 此方法会保留已经打开的模态。需要先确认并关闭模态时，向 submit 提交 .push 请求。
    public func push(_ destination: Destination, on scope: Scope? = nil) {
        let targetStack = scope.map(NavigationStackID.scope) ?? rootLayer.selectedStack
        guard rootLayer.route.destination.providesNavigationContainer || targetStack == .primary,
              let state = rootLayer.stacks[targetStack] else { return }
        rootLayer.selectedStack = targetStack
        state.path.append(destination)
    }

    /// 从当前最上层模态继续打开 sheet；没有模态时从 App 根层打开。
    /// 容器页面显式传入各栈根；返回值表示是否接受操作，不代表页面已经显示。
    @discardableResult
    public func presentSheet(
        _ destination: Destination,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    ) -> Bool {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        return context.present(
            destination, style: .sheet, initialStack: initialStack, rootDestinations: rootDestinations, paths: paths
        )
    }

    /// 从当前最上层模态继续打开全屏页；没有模态时从 App 根层打开。
    /// 容器页面显式传入各栈根；返回值表示是否接受操作，不代表页面已经显示。
    @discardableResult
    public func presentFullScreen(
        _ destination: Destination,
        initialStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:]
    ) -> Bool {
        let context = frontmostPresentationNode.map { presentationContext(for: $0) } ?? rootPresentation
        return context.present(
            destination, style: .fullScreen, initialStack: initialStack, rootDestinations: rootDestinations,
            paths: paths
        )
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
        if !rootLayer.route.destination.providesNavigationContainer {
            guard request.stack == .primary else { return .rejected }
        }
        // 换根请求显式提供了根，可以声明新栈；其他请求不得创建无根栈。
        switch request {
        case .setRoot: break
        default:
            guard rootLayer.stacks[request.stack] != nil else { return .rejected }
        }
        let result = coordinationState.submit(
            request, confirmIfPresented: confirmIfPresented,
            alert: hasBusinessAlert ? .business : (hasActiveAlert ? .confirmation : .none),
            hasPresentation: hasActivePresentation || isAwaitingPresentationDismissal
        )
        switch result {
        case .deferredUntilPresentationDismisses:
            rootLayer.isAwaitingDismissal = true
            dismissAllPresentations()
        case .applied:
            apply(request)
        case .rejected, .awaitingConfirmation, .deferredUntilAlertDismisses:
            break
        }
        return result
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
        let request = coordinationState.presentationDidDismiss()
        rootLayer.isAwaitingDismissal = false
        guard let request else { return nil }
        apply(request)
        return request
    }

    /// 关闭 App 根层打开的模态及其全部子模态，保留根层各栈的路径和待确认请求。
    /// 有活动 alert 时，先等提示关闭及按钮动作完成；模态数据清空后，仍需等待关闭动画完成。
    public func dismissAllPresentations() {
        if hasActiveAlert {
            coordinationState.deferAllDismissalsUntilAlertEnds()
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
        rootLayer.selectedStack = request.stack
        switch request {
        case .selectStack:
            break
        case let .setRoot(destination, stack):
            rootLayer.setRoot(destination, for: stack)
        case let .replacePath(path, stack):
            rootLayer.stacks[stack]?.path = path
        case let .push(destination, stack):
            rootLayer.stacks[stack]?.path.append(destination)
        }
    }
}
