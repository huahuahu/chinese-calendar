import SwiftUI

/// 跟随根宿主存活，按呈现身份释放业务会话；不参与 Core 的关闭完成和导航协调。
struct CalendarNavigationSessionCleanup: ViewModifier {
    let coordinator: CalendarHomeCoordinator

    func body(content: Content) -> some View {
        content
            .onChange(of: coordinator.router.navigation.retainedPresentationRoutes) {
                coordinator.releaseDismissedContexts()
            }
            .onChange(of: coordinator.router.navigation.alertRoutes) {
                coordinator.releaseDismissedContexts()
            }
            .onChange(of: coordinator.presentationSessionIDs, initial: true) {
                coordinator.releaseDismissedContexts()
            }
    }
}
