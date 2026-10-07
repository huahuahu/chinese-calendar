import Foundation

public extension CalendarStringKey.Calendar {
    enum MonthNavigation {}
}

public extension CalendarStringKey.Calendar.MonthNavigation {
    static var today: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.today",
            defaultValue: "今天",
            comment: "日历工具栏定位到今天所在日期和农历月的操作名称。"
        )
    }

    static var previous: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.previous",
            defaultValue: "上个月",
            comment: "日历年月导航中切换到前一个农历月的按钮名称。"
        )
    }

    static var previousHelp: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.previousHelp",
            defaultValue: "切换到上个月",
            comment: "日历上个月按钮的帮助提示，说明会切换当前农历月。"
        )
    }

    static var next: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.next",
            defaultValue: "下个月",
            comment: "日历年月导航中切换到后一个农历月的按钮名称。"
        )
    }

    static var nextHelp: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.nextHelp",
            defaultValue: "切换到下个月",
            comment: "日历下个月按钮的帮助提示，说明会切换当前农历月。"
        )
    }

    static var missingYear: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthNavigation.missingYear",
            defaultValue: "年份数据缺失",
            comment: "日历年月导航无法读取所属年份时的占位说明。"
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
