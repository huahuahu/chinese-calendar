#if DEBUG
    import ChineseCalendarLocalization
    import NavigationCore
    import SwiftUI

    /// 同层混合普通栈与 App SplitView；各 Tab 使用各自的 SDK 详情栈。
    struct CalendarDebugNavigationTabsView: View {
        @Environment(CalendarPresentationContext.self) private var presentation

        var body: some View {
            @Bindable var presentation = presentation
            TabView(selection: $presentation.selectedStack) {
                Tab(value: .scope(CalendarTab.years)) {
                    NavigationScopeView(stack: .scope(.years), presentation: presentation)
                } label: {
                    Text(CalendarStringKey.Debug.Split.ordinary)
                }
                Tab(value: .scope(CalendarTab.history)) {
                    CalendarDebugSplitView(layout: .twoColumn, stack: .scope(.history))
                } label: {
                    Text(CalendarStringKey.Debug.Split.twoColumn)
                }
                Tab(value: .scope(CalendarTab.settings)) {
                    CalendarDebugSplitView(layout: .threeColumn, stack: .scope(.settings))
                } label: {
                    Text(CalendarStringKey.Debug.Split.threeColumn)
                }
            }
        }
    }
#endif
