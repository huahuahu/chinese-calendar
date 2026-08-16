import SwiftUI

/// 显示在主页弹出的 sheet 或全屏场景中，承载独立的路由导航栈。
struct CalendarPresentationNodeView: View {
    @Bindable var node: CalendarPresentationNode
    let dismiss: () -> Void

    var body: some View {
        destinationNavigationStack(destination: node.destination)
            .sheet(item: $node.sheet) { child in
                CalendarPresentationNodeView(node: child) {
                    node.dismissSheet()
                }
            }
            .calendarFullScreenCover(item: $node.fullScreen) { child in
                CalendarPresentationNodeView(node: child) {
                    node.dismissFullScreen()
                }
            }
    }

    private func destinationNavigationStack(destination: CalendarDestination) -> some View {
        NavigationStack(path: $node.path) {
            destinationView(for: destination)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭", action: dismiss)
                    }
                }
                .calendarDestinations(emptyStateDescription: "请选择一个农历年。")
        }
    }

    private func destinationView(for destination: CalendarDestination) -> some View {
        CalendarDestinationView(
            destination: destination,
            emptyStateDescription: "请选择一个农历年。"
        )
    }
}
