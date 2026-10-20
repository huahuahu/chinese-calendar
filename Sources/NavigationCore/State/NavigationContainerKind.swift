// swiftformat:disable modifierOrder

/// Core 负责提供的导航结构，与页面是否自行组织 TabView 是两个维度。
nonisolated public enum NavigationContainerKind: String, Codable, Hashable, Sendable {
    case stack
    /// 声明保留给 #146；尚无状态、栏目联动和宽窄折叠实现。
    case twoColumn
    case threeColumn

    public var isSupported: Bool {
        self == .stack
    }
}
