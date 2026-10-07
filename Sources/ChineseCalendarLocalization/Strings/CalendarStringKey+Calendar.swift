import Foundation

public extension CalendarStringKey.Calendar {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.title",
            defaultValue: "日历",
            comment: "界面文案：Calendar.title。"
        )
    }
}
