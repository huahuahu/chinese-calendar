import SwiftUI

/// 等宽日期网格：先测量单元格的最小宽度，再根据容器宽度决定列数。
nonisolated struct LunarDayGridLayout: Layout {
    var spacing: CGFloat = 8

    func makeCache(subviews: Subviews) -> LunarDayGridLayoutCache {
        // 等实际收到尺寸提议时再测量。
        LunarDayGridLayoutCache()
    }

    func updateCache(_ cache: inout LunarDayGridLayoutCache, subviews: Subviews) {
        // SwiftUI 在布局或子视图变化时调用这里；文字、字号等变化后必须重新测量。
        cache = makeCache(subviews: subviews)
    }

    /// 测量阶段：向父视图报告整个网格需要的尺寸，此时不放置子视图。
    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout LunarDayGridLayoutCache
    ) -> CGSize {
        arrangement(proposedWidth: proposal.width, subviews: subviews, cache: &cache).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout LunarDayGridLayoutCache
    ) {
        // 放置阶段使用父视图最终分配的 bounds；它的宽度可能与先前的提议不同。
        let frames = arrangement(proposedWidth: bounds.width, subviews: subviews, cache: &cache).frames
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    func columnCount(availableWidth: CGFloat, minimumWidth: CGFloat, itemCount: Int) -> Int {
        guard itemCount > 0 else { return 0 }
        // n 列需要 n * minimumWidth + (n - 1) * spacing，解出 n 后向下取整。
        // 即使容器很窄也保留一列，列数最多等于单元格数量。
        let fittingCount = ((availableWidth + spacing) / (minimumWidth + spacing)).rounded(.down)
        return max(1, Int(min(CGFloat(itemCount), fittingCount)))
    }

    private func arrangement(
        proposedWidth: CGFloat?,
        subviews: Subviews,
        cache: inout LunarDayGridLayoutCache
    ) -> (size: CGSize, frames: [CGRect]) {
        guard !subviews.isEmpty else { return (.zero, []) }

        // 提议零宽是探测下限，不是强制压成零宽。LunarDayCellLayout 会保留农历日、干支的完整宽度，
        // 外层 padding 也计入返回值；取所有格子的最大值并向上取整，避免分配不足。
        // 内容下限与容器宽度无关，在本轮缓存有效期间只测量一次。
        let minimumWidth = cache.minimumWidth ?? ceil(subviews.map {
            $0.sizeThatFits(ProposedViewSize(width: 0, height: nil)).width
        }.max() ?? 0)
        cache.minimumWidth = minimumWidth
        // 未指定宽度或宽度为无穷大时，以所有格子排成一行作为理想宽度。
        // 有限宽度也不能小于一格的内容下限；极窄容器下优先保证单行文字完整。
        let idealWidth = minimumWidth * CGFloat(subviews.count) + spacing * CGFloat(subviews.count - 1)
        let finiteWidth = proposedWidth.flatMap { $0.isFinite ? $0 : nil }
        let width = max(minimumWidth, finiteWidth ?? idealWidth)

        // 按最终采用的宽度匹配，使测量和放置可以共用结果，零宽等提议也能命中同一下限。
        if let cached = cache.arrangement, cache.arrangementSpacing == spacing, cached.size.width == width {
            return cached
        }

        let columns = columnCount(availableWidth: width, minimumWidth: minimumWidth, itemCount: subviews.count)
        // 扣除列间距后均分剩余宽度，再按实际列宽测量高度，让长民用日期自然换行。
        let columnWidth = (width - CGFloat(columns - 1) * spacing) / CGFloat(columns)
        let childProposal = ProposedViewSize(width: columnWidth, height: nil)
        let heights = subviews.map { $0.sizeThatFits(childProposal).height }
        var frames: [CGRect] = []
        var y: CGFloat = 0

        for rowStart in stride(from: 0, to: subviews.count, by: columns) {
            let rowRange = rowStart ..< min(rowStart + columns, subviews.count)
            // 同排格子使用该排的最大高度；某个日期换行时整排增高，下一排不会与它重叠。
            let rowHeight = rowRange.map { heights[$0] }.max() ?? 0
            for index in rowRange {
                frames.append(CGRect(
                    x: CGFloat(index - rowStart) * (columnWidth + spacing),
                    y: y,
                    width: columnWidth,
                    height: rowHeight
                ))
            }
            y += rowHeight + spacing
        }

        // 最后一排后面不需要额外行间距。
        let size = CGSize(width: width, height: y - spacing)
        cache.arrangementSpacing = spacing
        cache.arrangement = (size, frames)
        return (size, frames)
    }
}
