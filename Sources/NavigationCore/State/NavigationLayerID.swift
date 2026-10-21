import Foundation

/// 标识 App 根层或某个模态层。每一层内部还可以包含多个 Tab。
///
/// 模态层使用对应模态节点的 UUID，层内的栈使用 NavigationStackID。
/// Context 的有效性还需核对原层对象，不能仅凭相同 ID 连接新的导航状态。
public enum NavigationLayerID: Hashable {
    /// App 根界面所在的层；根 Tab 共用这一层打开的模态。
    case root
    /// 指定模态内部的层，保存它自己的导航栈和从这里继续打开的子模态。
    case presentation(UUID)
}
