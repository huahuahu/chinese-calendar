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
            comment: "日历页面中逐日展示农历日期的网格分区标题。"
        )
    }

    static var subtitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.subtitle",
            defaultValue: "连续日序",
            comment: "农历月格的辅助说明，表示按农历月内日序连续排列，不按星期分组。"
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
            comment: "农历月格尚未获得完整日期数据时的空状态标题。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.empty.title",
            defaultValue: "没有日期数据",
            comment: "农历月格没有逐日记录时的空状态标题。"
        )
    }

    static var requiresFullDataMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.empty.requiresFullDataMessage",
            defaultValue: "请先下载完整日期数据。",
            comment: "农历月格因只有基础数据而为空时，提示用户下载完整日期数据。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.monthGrid.empty.message",
            defaultValue: "这个月份暂时没有可显示的日级记录。",
            comment: "农历月格为空时，说明该月没有可展示的逐日记录。"
        )
    }
}
