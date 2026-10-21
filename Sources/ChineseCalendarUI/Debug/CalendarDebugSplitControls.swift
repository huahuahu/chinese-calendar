#if DEBUG
    import ChineseCalendarLocalization
    import SwiftUI

    /// 前栏与详情页共用的选择动作，显式操作同一个 detail 栈。
    struct CalendarDebugSplitControls: View {
        let state: CalendarDebugSplitState

        var body: some View {
            Section {
                Button(CalendarStringKey.Debug.Split.nextItem) {
                    state.selectItem(state.item?.next ?? .first)
                }
                Button(CalendarStringKey.Debug.Split.repeatSelection) {
                    state.selectItem(state.item)
                }
                .disabled(state.item == nil)
                Button(CalendarStringKey.Debug.Split.clearSelection) {
                    state.selectItem(nil)
                }
                .disabled(state.item == nil)
                Button(CalendarStringKey.Debug.Split.showDetail) {
                    state.showDetail()
                }
                .disabled(state.item == nil)
                Button(CalendarStringKey.Debug.Split.showSidebar) {
                    state.preferredCompactColumn = .sidebar
                    state.columnVisibility = .all
                }
                Button(CalendarStringKey.Debug.Split.showAllColumns) {
                    state.columnVisibility = .all
                }
            } footer: {
                Text(CalendarStringKey.Debug.Split.message)
            }
        }
    }
#endif
