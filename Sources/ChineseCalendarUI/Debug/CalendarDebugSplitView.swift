#if DEBUG
    import NavigationCore
    import SwiftUI

    /// 每个完整分栏实例拥有自己的布局状态，选中的对象仍由详情栈根表达。
    struct CalendarDebugSplitView: View {
        let layout: CalendarDebugSplitLayout
        var stack: NavigationStackID<CalendarTab> = .primary
        @Environment(CalendarPresentationContext.self) private var presentation

        var body: some View {
            let navigation = presentation.context(for: stack)
            CalendarDebugSplitContainer(
                layout: layout, stack: stack, presentation: presentation, navigation: navigation
            )
            .id(ObjectIdentifier(navigation))
        }
    }
#endif
