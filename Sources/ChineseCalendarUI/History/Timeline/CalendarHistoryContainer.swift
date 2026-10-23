import NavigationCore
import SwiftUI

/// 布局状态属于这个容器实例，不随数据库查询子树重建或子页面覆盖而释放。
struct CalendarHistoryContainer: View {
    let stack: NavigationStackID<CalendarTab>
    let navigation: CalendarNavigationContext
    @State private var state: CalendarHistoryState
    @Environment(ChineseCalendarStoreCoordinator.self) private var storeCoordinator: ChineseCalendarStoreCoordinator?

    init(stack: NavigationStackID<CalendarTab>, navigation: CalendarNavigationContext) {
        self.stack = stack
        self.navigation = navigation
        _state = State(initialValue: CalendarHistoryState(navigation: navigation))
    }

    var body: some View {
        CalendarHistorySplitContent(stack: stack, navigation: navigation, state: state)
            .calendarStoreContent(state: storeCoordinator?.state)
            .onChange(of: navigation.rootDestination) {
                state.synchronizeRoot()
            }
    }
}
