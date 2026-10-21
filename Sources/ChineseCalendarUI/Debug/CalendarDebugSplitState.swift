#if DEBUG
    import Observation
    import SwiftUI

    /// App 持有分类与布局；对象选择投影详情根 Destination，路径只保存在同一 SDK 栈中。
    @MainActor
    @Observable
    final class CalendarDebugSplitState {
        private(set) var category: CalendarDebugSplitCategory?
        private let navigation: CalendarNavigationContext
        var item: CalendarDebugSplitItem? {
            guard case let .debugSplitDetail(item, _) = navigation.rootDestination else { return nil }
            return item
        }

        var retainsDetail = false
        var columnVisibility: NavigationSplitViewVisibility = .all
        var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

        init(navigation: CalendarNavigationContext) {
            self.navigation = navigation
        }

        @discardableResult
        func selectCategory(_ category: CalendarDebugSplitCategory?) -> Bool {
            let keepsDetail = self.category == category || retainsDetail
            let accepted = keepsDetail
                ? navigation.setPath(navigation.path)
                : navigation.setRootDestination(.debugSplitEmpty)
            guard accepted else { return false }
            self.category = category
            preferredCompactColumn = category == nil ? .sidebar : .content
            return true
        }

        @discardableResult
        func selectItem(_ item: CalendarDebugSplitItem?) -> Bool {
            // 先确认栈接受修改，再同步选择；待确认、关闭和 alert 期间不提前换根。
            let changesItem = self.item != item
            let root = item.map { CalendarDestination.debugSplitDetail(item: $0, level: 0) } ?? .debugSplitEmpty
            let accepted = changesItem || item == nil
                ? navigation.setRootDestination(root)
                : navigation.setPath(navigation.path)
            guard accepted else { return false }
            if let item {
                if changesItem { category = item.category }
                preferredCompactColumn = .detail
            }
            return true
        }

        func showDetail() {
            guard item != nil, navigation.setPath(navigation.path) else { return }
            preferredCompactColumn = .detail
        }
    }
#endif
