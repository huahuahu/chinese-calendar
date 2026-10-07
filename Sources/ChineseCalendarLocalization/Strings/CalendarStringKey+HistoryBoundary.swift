import Foundation

public extension CalendarStringKey.History {
    enum Boundary {}
}

public extension CalendarStringKey.History.Boundary {
    enum Comparison {}
    enum Event {}
    enum Source {}

    static var claimed: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.claimed",
            defaultValue: "自称",
            comment: "历史边界对照中的来源类别标签，表示朝代自称的起止时间。"
        )
    }

    static var orthodox: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.orthodox",
            defaultValue: "正统",
            comment: "历史边界对照中的来源类别标签，表示正统时间线采用的起止时间。"
        )
    }

    static var start: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.start",
            defaultValue: "开始",
            comment: "历史边界对照中开始日期一行的标签。"
        )
    }

    static var end: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.end",
            defaultValue: "结束",
            comment: "历史边界对照中结束日期一行的标签。"
        )
    }

    static var unknown: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.unknown",
            defaultValue: "不详",
            comment: "历史边界缺少可确定日期时的简短占位文字。"
        )
    }

    static var missingData: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.missingData",
            defaultValue: "当前数据缺失",
            comment: "历史边界单元格缺少可显示资料时的占位文字。"
        )
    }

    static var period: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.period",
            defaultValue: "正统期",
            comment: "历史起讫页面中正统时期记录的类别标签。"
        )
    }

    static var claimedDynasty: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.claimedDynasty",
            defaultValue: "朝代自称",
            comment: "历史边界摘要中标识朝代自称时间范围的栏目标题。"
        )
    }

    static var timeline: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.timeline",
            defaultValue: "正统时间线",
            comment: "历史边界摘要中标识正统时间线所采用日期的栏目标题。"
        )
    }

    static func monthIndex(index: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.monthIndex",
            defaultValue: "月序 \(index)",
            comment: "边界日期；参数为连续农历月序。"
        )
    }

    static func dayIndex(index: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.dayIndex",
            defaultValue: "日序 \(index)",
            comment: "边界日期；参数为连续日序。"
        )
    }

    static func namedPeriod(name: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.namedPeriod",
            defaultValue: "正统期 · \(name)",
            comment: "正统时期标题；参数为来源数据中的时期名。"
        )
    }
}

public extension CalendarStringKey.History.Boundary.Comparison {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.title",
            defaultValue: "时间边界",
            comment: "朝代详情中比较自称与正统起止日期的分区标题。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.message",
            defaultValue: "对比朝代自称起止与正统时间线采用的边界。",
            comment: "朝代详情的时间边界分区说明，解释正在比较自称起止与正统时间线。"
        )
    }

    static var missingMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.missingMessage",
            defaultValue: "当前 SwiftData store 还没有为这个朝代关联正统开始和结束边界。",
            comment: "朝代边界对照缺少正统边界关系时，解释当前存储中的资料缺口。"
        )
    }

    static var differentPrecision: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.differentPrecision",
            defaultValue: "边界精度不同",
            comment: "历史边界比较结果，表示两个日期的记录精度不一致。"
        )
    }

    static var sameSource: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.sameSource",
            defaultValue: "同一来源文本",
            comment: "历史边界比较结果，表示两个日期保留了相同来源文字。"
        )
    }

    static var differentSource: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.differentSource",
            defaultValue: "边界来源不同",
            comment: "历史边界比较结果，表示两个日期来自不同的来源文字。"
        )
    }

    static var sameYear: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.sameYear",
            defaultValue: "同年",
            comment: "历史边界比较结果，表示两个边界落在同一年。"
        )
    }

    static var sameBoundary: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.sameBoundary",
            defaultValue: "同一边界",
            comment: "历史边界比较结果，表示自称与正统记录指向同一边界。"
        )
    }

    static var differentBoundary: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.differentBoundary",
            defaultValue: "边界不同",
            comment: "历史边界比较结果，表示自称与正统记录的边界不相同。"
        )
    }

    static func later(years: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.later",
            defaultValue: "正统晚 \(years) 年",
            comment: "边界比较；参数为正统边界晚于自称边界的年数。"
        )
    }

    static func earlier(years: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.earlier",
            defaultValue: "正统早 \(years) 年",
            comment: "边界比较；参数为正统边界早于自称边界的年数。"
        )
    }

    static func startSummary(difference: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.startSummary",
            defaultValue: "开始\(difference)",
            comment: "开始边界差异；参数为比较结果。"
        )
    }

    static func endSummary(difference: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.endSummary",
            defaultValue: "结束\(difference)",
            comment: "结束边界差异；参数为比较结果。"
        )
    }

    static func summary(start: String, end: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.comparison.summary",
            defaultValue: "开始\(start)，结束\(end)",
            comment: "起止边界差异摘要；参数依次为开始和结束的比较结果。"
        )
    }
}

public extension CalendarStringKey.History.Boundary.Event {
    static func startTitle(dynasty: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.event.startTitle",
            defaultValue: "\(dynasty)正统期开始",
            comment: "正统时间线边界事件；参数为朝代简称。"
        )
    }

    static func startDetail(dynasty: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.event.startDetail",
            defaultValue: "\(dynasty)从这一边界进入当前正统时间线。",
            comment: "正统时间线边界事件；参数为朝代简称。"
        )
    }

    static func endTitle(dynasty: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.event.endTitle",
            defaultValue: "\(dynasty)正统期结束",
            comment: "正统时间线边界事件；参数为朝代简称。"
        )
    }

    static func endDetail(dynasty: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.event.endDetail",
            defaultValue: "当前正统时间线在这一边界结束\(dynasty)时期。",
            comment: "正统时间线边界事件；参数为朝代简称。"
        )
    }
}

public extension CalendarStringKey.History.Boundary.Source {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.source.title",
            defaultValue: "来源和精度",
            comment: "历史边界详情中展示原始来源及日期精度的分区标题。"
        )
    }

    static var claimedStart: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.source.claimedStart",
            defaultValue: "自称开始",
            comment: "边界来源详情中朝代自称开始日期的字段标题。"
        )
    }

    static var orthodoxStart: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.source.orthodoxStart",
            defaultValue: "正统开始",
            comment: "边界来源详情中正统时间线开始日期的字段标题。"
        )
    }

    static var claimedEnd: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.source.claimedEnd",
            defaultValue: "自称结束",
            comment: "边界来源详情中朝代自称结束日期的字段标题。"
        )
    }

    static var orthodoxEnd: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.source.orthodoxEnd",
            defaultValue: "正统结束",
            comment: "边界来源详情中正统时间线结束日期的字段标题。"
        )
    }

    static func detail(precision: String, source: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.source.detail",
            defaultValue: "\(precision) · \(source)",
            comment: "边界来源详情；参数依次为精度/索引和未经改写的来源文本。"
        )
    }

    static func notedDetail(precision: String, source: String, note: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.boundary.source.notedDetail",
            defaultValue: "\(precision) · \(source) · \(note)",
            comment: "带备注的边界来源详情；参数依次为精度/索引、来源文本、来源备注。"
        )
    }
}
