import SwiftUI

/// 单元格内部的纵向布局。子视图顺序约定为：农历日、干支、民用日期。
/// 前两项的完整单行宽度决定下限，民用日期允许换行，不参与最小宽度计算。
nonisolated struct LunarDayCellLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        guard !subviews.isEmpty else { return .zero }

        let width = contentWidth(proposedWidth: proposal.width, subviews: subviews)
        // 固定可用宽度、不限制高度，测出民用日期换行后的完整高度，再加上项间距。
        let childProposal = ProposedViewSize(width: width, height: nil)
        let contentHeight = subviews.reduce(CGFloat.zero) {
            $0 + $1.sizeThatFits(childProposal).height
        } + spacing * CGFloat(subviews.count - 1)
        let proposedHeight = proposal.height.flatMap { $0.isFinite ? $0 : nil } ?? 0

        // 网格会传入同排的统一高度；可以拉高格子，但不能把内容压矮。
        return CGSize(width: width, height: max(contentHeight, proposedHeight))
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // 使用最终分配的宽度重新测量，按各项的实际高度向下排列，额外空白留在底部。
        let childProposal = ProposedViewSize(width: bounds.width, height: nil)
        var y = bounds.minY

        for subview in subviews {
            subview.place(at: CGPoint(x: bounds.minX, y: y), anchor: .topLeading, proposal: childProposal)
            y += subview.sizeThatFits(childProposal).height + spacing
        }
    }

    private func contentWidth(proposedWidth: CGFloat?, subviews: Subviews) -> CGFloat {
        // .unspecified 询问视图不受尺寸限制时的理想宽度，包含当前字体和子视图自身的 padding。
        // 只测前两项，避免长民用日期把整列撑宽；系统字号变化也会反映在测量结果中。
        let minimumWidth = subviews.prefix(2).map {
            $0.sizeThatFits(.unspecified).width
        }.max() ?? 0
        let finiteWidth = proposedWidth.flatMap { $0.isFinite ? $0 : nil }
        // 接受更宽的提议，但不低于内容下限；外层单元格的 padding 由 SwiftUI 另外计入。
        return max(minimumWidth, finiteWidth ?? minimumWidth)
    }
}
