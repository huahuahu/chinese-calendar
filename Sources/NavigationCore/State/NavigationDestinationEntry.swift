// swiftformat:disable modifierOrder

/// 承载入口不等于页面的运行时位置；是否在 App 根层仍读取层 ID。
nonisolated public enum NavigationDestinationEntry: Hashable, Sendable {
    case root
    case stackRoot
    case presentation
    case push
}
