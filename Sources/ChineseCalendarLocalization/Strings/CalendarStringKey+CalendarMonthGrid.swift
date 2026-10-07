import Foundation

public extension CalendarStringKey.Calendar {
    enum MonthGrid {}
}

public extension CalendarStringKey.Calendar.MonthGrid {
    enum Day {}
    enum Empty {}

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.title",
            defaultValue: "农历月格",
            comment: "界面文案：Calendar.MonthGrid.title。"
        )
    }

    static var subtitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.subtitle",
            defaultValue: "连续日序",
            comment: "界面文案：Calendar.MonthGrid.subtitle。"
        )
    }
}

public extension CalendarStringKey.Calendar.MonthGrid.Day {
    static func accessibilityLabel(day: String, stemBranch: String, civilDate: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.day.accessibilityLabel",
            defaultValue: "\(day)，日干支，\(stemBranch)，\(civilDate)",
            comment: "月格日期朗读；参数依次为农历日名、日干支、公历日期。"
        )
    }

    static func todayAccessibilityLabel(day: String, stemBranch: String, civilDate: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.day.todayAccessibilityLabel",
            defaultValue: "\(day)，今天，日干支，\(stemBranch)，\(civilDate)",
            comment: "今天的月格朗读；参数依次为农历日名、日干支、公历日期。"
        )
    }
}

public extension CalendarStringKey.Calendar.MonthGrid.Empty {
    static var requiresFullDataTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.empty.requiresFullDataTitle",
            defaultValue: "完整日期数据尚未下载",
            comment: "界面文案：Calendar.MonthGrid.Empty.requiresFullDataTitle。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.empty.title",
            defaultValue: "没有日期数据",
            comment: "界面文案：Calendar.MonthGrid.Empty.title。"
        )
    }

    static var requiresFullDataMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.empty.requiresFullDataMessage",
            defaultValue: "请先下载完整日期数据。",
            comment: "界面文案：Calendar.MonthGrid.Empty.requiresFullDataMessage。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.empty.message",
            defaultValue: "这个月份暂时没有可显示的日级记录。",
            comment: "界面文案：Calendar.MonthGrid.Empty.message。"
        )
    }
}
