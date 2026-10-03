import SwiftUI

/// 只缓存尺寸和相对位置，不持有子视图；SwiftUI 可以随时重建，不影响布局结果。
nonisolated struct LunarDayGridLayoutCache {
    var minimumWidth: CGFloat?
    var arrangementSpacing: CGFloat?

    /// 仅保留最近一次排列，避免拖动宽度滑块时不断积累缓存。
    var arrangement: (size: CGSize, frames: [CGRect])?
}
