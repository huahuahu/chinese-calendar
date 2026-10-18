import NavigationCore

/// 当前栈的 push/pop 入口；页面呈现单独读取 CalendarPresentationContext。
typealias CalendarNavigationContext = NavigationContext<CalendarTab, CalendarDestination>

/// 当前层的模态入口；各栈注入的入口共享层状态，并保留各自的发起栈身份。
typealias CalendarPresentationContext = NavigationPresentationContext<CalendarTab, CalendarDestination, CalendarAlert>
