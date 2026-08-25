import NavigationCore
import SwiftUI

/// 显示在主页弹出的 sheet 或全屏场景中，承载独立的路由导航栈。
struct CalendarPresentationNodeView: View {
    let node: CalendarPresentationNode
    @Environment(CalendarRouter.self) private var router

    var body: some View {
        NavigationCore.NavigationPresentationNodeView(
            node: node,
            onDismiss: router.presentationDidDismiss
        ) { destination, dismiss in
            CalendarDestinationView(destination: destination)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭", action: dismiss)
                    }
                }
        }
    }
}
