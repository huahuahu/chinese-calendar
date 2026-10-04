/// 保存当前这一次农历年份切换的方向。
///
/// 入场和离场 transition 共享同一个引用，确保它们都使用用户刚刚选择的导航方向，
/// 而不是各自创建时的历史方向。
@MainActor
final class LunarYearTransitionContext {
    var direction: LunarYearTransitionDirection

    init(direction: LunarYearTransitionDirection = .later) {
        self.direction = direction
    }
}
