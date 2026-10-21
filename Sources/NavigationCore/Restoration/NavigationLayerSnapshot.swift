import Foundation

/// 保存根层或模态层的导航状态数据副本，用于之后恢复。
///
/// 这里记录该层所有栈的栈底页面和 push 路径，包括未选中的栈。
/// 打开整层时使用的 Destination 由 NavigationSnapshot.rootDestination 或
/// NavigationPresentationSnapshot.node 的 destination 保存；后者还保存模态 ID 和展示方式。
public struct NavigationLayerSnapshot<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
> {
    /// 当前选中的导航栈。尚未 push 页面时，该栈可以没有 paths 条目。
    public let selectedStack: NavigationStackID<Scope>
    /// 每个导航栈的栈底页面，不包含之后 push 的页面。
    /// 例如打开 .tabs 模态后，首页栈从 .home 开始，历史栈从 .history 开始。
    /// .tabs 由所属根快照或模态快照记录，这里只记录各栈的 .home、.history。
    public let rootDestinations: [NavigationStackID<Scope>: Destination]
    /// 各栈已经 push 的页面列表，包括未选中的栈；每条列表均不含栈底页面。
    public let paths: [NavigationStackID<Scope>: [Destination]]
    /// 从这一层打开的子模态快照，其中会继续保存更深层的模态。
    public let presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>?

    public init(
        selectedStack: NavigationStackID<Scope> = .primary,
        rootDestinations: [NavigationStackID<Scope>: Destination] = [:],
        paths: [NavigationStackID<Scope>: [Destination]] = [:],
        presentation: NavigationPresentationSnapshot<Scope, Destination, AlertRoute>? = nil
    ) {
        self.selectedStack = selectedStack
        self.rootDestinations = rootDestinations
        self.paths = paths.filter { !$0.value.isEmpty }
        self.presentation = presentation
    }

    var destinations: [Destination] {
        Array(rootDestinations.values) + paths.values.flatMap(\.self) + (presentation?.destinations ?? [])
    }

    /// 为 App 根界面或新打开的模态生成初始栈状态。
    /// 页面自带 TabView／SplitView 等容器时使用传入的栈配置；否则只创建 primary 栈。
    init?(
        destination: Destination,
        initialStack: NavigationStackID<Scope>,
        rootDestinations: [NavigationStackID<Scope>: Destination],
        paths: [NavigationStackID<Scope>: [Destination]]
    ) {
        if destination.providesNavigationContainer {
            guard rootDestinations[initialStack] != nil,
                  paths.keys.allSatisfy({ rootDestinations[$0] != nil }) else { return nil }
            self.init(selectedStack: initialStack, rootDestinations: rootDestinations, paths: paths)
        } else {
            guard initialStack == .primary, rootDestinations.isEmpty,
                  paths.keys.allSatisfy({ $0 == .primary }) else { return nil }
            self.init(selectedStack: .primary, rootDestinations: [.primary: destination], paths: paths)
        }
    }

    /// 所有选中栈和带路径栈都必须声明根；不恢复无根栈。
    /// Core 自动提供 NavigationStack 时，只允许 primary 栈且必须记录其栈底页面；
    /// 栈底可以被替换，因此不要求它仍等于打开这一层时的 destination。
    func validate(for destination: Destination, identities: inout Set<UUID>) -> Bool {
        guard rootDestinations[selectedStack] != nil,
              paths.keys.allSatisfy({ rootDestinations[$0] != nil }) else { return false }
        if !destination.providesNavigationContainer {
            guard selectedStack == .primary, rootDestinations.count == 1,
                  rootDestinations[.primary] != nil,
                  paths.keys.allSatisfy({ $0 == .primary }) else { return false }
        }
        return presentation?.validate(identities: &identities) ?? true
    }
}

extension NavigationLayerSnapshot: Codable where Scope: Codable, Destination: Codable, AlertRoute: Codable {
    private enum CodingKeys: String, CodingKey {
        case selectedStack, rootDestinations, paths, presentation
    }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            selectedStack: values.decode(NavigationStackID<Scope>.self, forKey: .selectedStack),
            rootDestinations: values.decode([NavigationStackID<Scope>: Destination].self, forKey: .rootDestinations),
            paths: values.decode([NavigationStackID<Scope>: [Destination]].self, forKey: .paths),
            presentation: values.decodeIfPresent(
                NavigationPresentationSnapshot<Scope, Destination, AlertRoute>.self, forKey: .presentation
            )
        )
    }
}

extension NavigationLayerSnapshot: Equatable where Scope: Equatable, Destination: Equatable {}
