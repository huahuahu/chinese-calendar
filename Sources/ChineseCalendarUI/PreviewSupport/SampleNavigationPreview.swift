import NavigationCore
import SwiftUI

/// 在 sampleData Preview 中复用已有导航宿主，为预览页和后续页面提供同一栈的环境。
struct SampleNavigationPreview<Content: View>: View {
    @Environment(CalendarHomeCoordinator.self) private var coordinator
    let tab: CalendarTab
    @ViewBuilder let content: () -> Content

    var body: some View {
        NavigationScopeView(
            stack: .scope(tab),
            presentation: coordinator.router.navigation.rootPresentation,
            root: content
        )
        .onAppear {
            coordinator.router.selectedTab = tab
        }
    }
}
