import Foundation

public extension CalendarStringKey.Calendar {
    enum Unavailable {}
}

public extension CalendarStringKey.Calendar.Unavailable {
    static var requiresFullDataTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.requiresFullDataTitle",
            defaultValue: "需要完整日期数据",
            comment: "日历目标因缺少逐日记录而不可用时的标题。"
        )
    }

    static var missingDateTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.missingDateTitle",
            defaultValue: "没有找到日期",
            comment: "日历导航目标对应日期不存在时的不可用状态标题。"
        )
    }

    static var requiresFullDataMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.requiresFullDataMessage",
            defaultValue: "当前内置数据只有年份和月份。请先下载完整日期数据，再浏览日历。",
            comment: "只有年份和月份基础数据时，解释逐日浏览需要先下载完整日期数据。"
        )
    }

    static var missingDateMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.unavailable.missingDateMessage",
            defaultValue: "当前导航地址无法解析为一个具体农历日。",
            comment: "日历目标无法解析为具体农历日时，解释导航内容不可用的原因。"
        )
    }
}
