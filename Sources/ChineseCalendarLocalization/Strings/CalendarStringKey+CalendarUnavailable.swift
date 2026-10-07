import Foundation

public extension CalendarStringKey.Calendar {
    enum Unavailable {}
}

public extension CalendarStringKey.Calendar.Unavailable {
    static var requiresFullDataTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.requiresFullDataTitle",
            defaultValue: "需要完整日期数据",
            comment: "界面文案：Calendar.Unavailable.requiresFullDataTitle。"
        )
    }

    static var missingDateTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.missingDateTitle",
            defaultValue: "没有找到日期",
            comment: "界面文案：Calendar.Unavailable.missingDateTitle。"
        )
    }

    static var requiresFullDataMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.requiresFullDataMessage",
            defaultValue: "当前内置数据只有年份和月份。请先下载完整日期数据，再浏览日历。",
            comment: "界面文案：Calendar.Unavailable.requiresFullDataMessage。"
        )
    }

    static var missingDateMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.missingDateMessage",
            defaultValue: "当前导航地址无法解析为一个具体农历日。",
            comment: "界面文案：Calendar.Unavailable.missingDateMessage。"
        )
    }
}
