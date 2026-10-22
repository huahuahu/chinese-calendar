/// 用“所属 NavigationLayer 的 ID + 层内栈 ID”查找缓存中的栈 Context。
///
/// 这样既能区分同一层的多个 Tab，也能区分根层和模态中同名的 Tab。
/// 找到缓存后仍需检查原栈对象是否有效，避免新状态使用相同 ID 时误用旧 Context。
struct NavigationContextID<Scope: NavigationScope>: Hashable {
    let layer: NavigationLayerID
    let stack: NavigationStackID<Scope>
}
