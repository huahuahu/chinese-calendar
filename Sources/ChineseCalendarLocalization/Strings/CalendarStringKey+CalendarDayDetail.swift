import Foundation

public extension CalendarStringKey.Calendar {
    enum DayDetail {}
}

public extension CalendarStringKey.Calendar.DayDetail {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.title",
            defaultValue: "选中日",
            comment: "界面文案：Calendar.DayDetail.title。"
        )
    }

    static var lunarExpressionLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.lunarExpressionLabel",
            defaultValue: "农历表达",
            comment: "界面文案：Calendar.DayDetail.lunarExpressionLabel。"
        )
    }

    static var sexagenaryLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.sexagenaryLabel",
            defaultValue: "日干支",
            comment: "界面文案：Calendar.DayDetail.sexagenaryLabel。"
        )
    }

    static var contentLevelLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.contentLevelLabel",
            defaultValue: "数据层级",
            comment: "界面文案：Calendar.DayDetail.contentLevelLabel。"
        )
    }

    static var civilDateLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.civilDateLabel",
            defaultValue: "对应日期",
            comment: "界面文案：Calendar.DayDetail.civilDateLabel。"
        )
    }

    static func subtitle(stemBranch: String, civilDate: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.subtitle",
            defaultValue: "\(stemBranch)日 · \(civilDate)",
            comment: "选中日副标题；参数依次为日干支和已格式化的公历日期。"
        )
    }

    static func lunarExpression(month: String, day: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.dayDetail.lunarExpression",
            defaultValue: "\(month)\(day)",
            comment: "农历表达；参数依次为带大小月的月名和农历日名。"
        )
    }
}
