import Foundation
import NavigationCore

/// 日历页面使用的栈 Context，操作本栈的栈底页面、path 和 push/pop。
/// 打开或关闭模态单独使用 CalendarPresentationContext。
typealias CalendarNavigationContext = NavigationContext<CalendarTab, CalendarDestination>

/// 日历页面使用的 NavigationPresentationContext，操作所在层的模态、alert 和选中栈。
/// 同层各栈的 NavigationPresentationContext 共享模态状态，默认记录各自的发起栈，以限制后台 Tab 打开模态。
typealias CalendarPresentationContext = NavigationPresentationContext<CalendarTab, CalendarDestination, CalendarAlert>

extension CalendarPresentationContext {
    /// 在当前层上打开一个包含日历、历史和设置 Tab 的新模态。
    /// 新模态的选中 Tab、各栈路径和子模态状态独立于父层；新模态内各 Tab 仍共享该层的呈现状态。
    @discardableResult
    func presentMainTabs(
        style: NavigationPresentationStyle = .sheet,
        selectedTab: CalendarTab = .years,
        paths: [NavigationStackID<CalendarTab>: [CalendarDestination]] = [:]
    ) -> NavigationPresentationResult {
        present(
            .mainTabs, style: style, initialStack: .scope(selectedTab),
            rootDestinations: CalendarRouter.mainTabRoots, paths: paths
        )
    }
}

#if DEBUG
    extension CalendarPresentationContext {
        /// 分栏容器与详情空态分别声明路由，详情栈从创建时就具有有效根页面。
        @discardableResult
        func presentDebugSplit(
            layout: CalendarDebugSplitLayout, style: NavigationPresentationStyle = .sheet
        ) -> NavigationPresentationResult {
            present(.debugSplit(layout: layout), style: style, rootDestinations: [.primary: .debugSplitEmpty])
        }

        @discardableResult
        func presentDebugNavigationTabs(
            id: UUID = UUID(), style: NavigationPresentationStyle = .fullScreen,
            selectedTab: CalendarTab = .years
        ) -> NavigationPresentationResult {
            present(
                .debugNavigationTabs(id: id), style: style, initialStack: .scope(selectedTab),
                rootDestinations: [
                    .scope(.years): .debugNavigation(id: id),
                    .scope(.history): .debugSplitEmpty, .scope(.settings): .debugSplitEmpty
                ]
            )
        }
    }
#endif
