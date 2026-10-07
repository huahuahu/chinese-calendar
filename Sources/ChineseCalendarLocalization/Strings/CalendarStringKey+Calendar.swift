import Foundation

public extension CalendarStringKey.Calendar {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.title",
            defaultValue: "日历",
            comment: "日历 Tab 及其日期浏览首页的导航标题。"
        )
    }
}
