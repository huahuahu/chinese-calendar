import Foundation

/// 标识 App 根层或某个模态层。每一层内部还可以包含多个 Tab。
///
/// 模态层使用对应模态节点的 UUID，层内的栈使用 NavigationStackID。
/// 恢复模态时会沿用其 UUID，但创建新的层对象，因此不能只凭 ID 判断旧 Context 是否仍有效。
public enum NavigationLayerID: Hashable {
    /// App 根界面所在的层；根 Tab 共用这一层打开的模态。
    case root
    /// 指定模态内部的层，保存它自己的导航栈和从这里继续打开的子模态。
    case presentation(UUID)
}
