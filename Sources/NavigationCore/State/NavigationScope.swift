// swiftformat:disable modifierOrder

/// 业务定义的导航栈命名标识；同名栈在不同导航层中互相隔离。
/// 仅标记导航用途并要求稳定的相等性与哈希，不声明页面、布局或业务状态。
nonisolated public protocol NavigationScope: Hashable {}
