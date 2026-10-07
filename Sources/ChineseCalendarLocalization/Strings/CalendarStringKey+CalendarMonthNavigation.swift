import Foundation

public extension CalendarStringKey.Calendar {
    enum MonthNavigation {}
}

public extension CalendarStringKey.Calendar.MonthNavigation {
    static var today: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.today",
            defaultValue: "今天",
            comment: "界面文案：Calendar.MonthNavigation.today。"
        )
    }

    static var previous: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.previous",
            defaultValue: "上个月",
            comment: "界面文案：Calendar.MonthNavigation.previous。"
        )
    }

    static var previousHelp: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.previousHelp",
            defaultValue: "切换到上个月",
            comment: "界面文案：Calendar.MonthNavigation.previousHelp。"
        )
    }

    static var next: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.next",
            defaultValue: "下个月",
            comment: "界面文案：Calendar.MonthNavigation.next。"
        )
    }

    static var nextHelp: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.nextHelp",
            defaultValue: "切换到下个月",
            comment: "界面文案：Calendar.MonthNavigation.nextHelp。"
        )
    }

    static var missingYear: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.missingYear",
            defaultValue: "年份数据缺失",
            comment: "界面文案：Calendar.MonthNavigation.missingYear。"
        )
    }

    static func title(year: String, month: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.title",
            defaultValue: "\(year) \(month)",
            comment: "年月导航主标题；参数依次为干支年名和农历月名。"
        )
    }
}
