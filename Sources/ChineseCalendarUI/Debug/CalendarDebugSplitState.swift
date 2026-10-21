#if DEBUG
    import Observation
    import SwiftUI

    /// App 持有前栏选择与布局；详情路径只保存在传入的 SDK 栈中。
    @MainActor
    @Observable
    final class CalendarDebugSplitState {
        private(set) var category: CalendarDebugSplitCategory?
        private(set) var item: CalendarDebugSplitItem?
        var retainsDetail = false
        var columnVisibility: NavigationSplitViewVisibility = .all
        var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

        @discardableResult
        func selectCategory(_ category: CalendarDebugSplitCategory?, navigation: CalendarNavigationContext) -> Bool {
            let keepsDetail = self.category == category || retainsDetail
            guard navigation.setPath(keepsDetail ? navigation.path : []) else { return false }
            self.category = category
            if !keepsDetail { item = nil }
            preferredCompactColumn = category == nil ? .sidebar : .content
            return true
        }

        @discardableResult
        func selectItem(_ item: CalendarDebugSplitItem?, navigation: CalendarNavigationContext) -> Bool {
            // 先确认栈接受修改，再同步选择；待确认、关闭和 alert 期间不提前换根。
            let changesItem = self.item != item
            guard navigation.setPath(changesItem ? [] : navigation.path) else { return false }
            self.item = item
            if let item {
                if changesItem { category = item.category }
                preferredCompactColumn = .detail
            }
            return true
        }

        func showDetail(navigation: CalendarNavigationContext) {
            guard item != nil, navigation.setPath(navigation.path) else { return }
            preferredCompactColumn = .detail
        }
    }
#endif
