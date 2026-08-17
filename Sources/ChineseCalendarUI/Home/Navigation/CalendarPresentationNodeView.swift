import NavigationCore
import SwiftUI

/// 显示在主页弹出的 sheet 或全屏场景中，承载独立的路由导航栈。
struct CalendarPresentationNodeView: View {
    let node: CalendarPresentationNode

    var body: some View {
        NavigationCore.NavigationPresentationNodeView(node: node) { destination, dismiss in
            CalendarDestinationView(
                destination: destination,
                emptyStateDescription: "请选择一个农历年。"
            )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭", action: dismiss)
                    }
                }
        }
    }
}
