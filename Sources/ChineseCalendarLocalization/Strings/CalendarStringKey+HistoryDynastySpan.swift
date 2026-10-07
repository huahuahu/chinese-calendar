import Foundation

public extension CalendarStringKey.History {
    enum DynastySpan {}
}

public extension CalendarStringKey.History.DynastySpan {
    enum Unavailable {}

    static var unavailableDuration: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.unavailableDuration",
            defaultValue: "国祚暂无",
            comment: "界面文案：History.DynastySpan.unavailableDuration。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.title",
            defaultValue: "朝代起讫",
            comment: "界面文案：History.DynastySpan.title。"
        )
    }

    static var boundaryEyebrow: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.boundaryEyebrow",
            defaultValue: "边界对照",
            comment: "界面文案：History.DynastySpan.boundaryEyebrow。"
        )
    }

    static var boundaryTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.boundaryTitle",
            defaultValue: "朝代自称与正统期",
            comment: "界面文案：History.DynastySpan.boundaryTitle。"
        )
    }

    static var eventsEyebrow: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.eventsEyebrow",
            defaultValue: "相关说明",
            comment: "界面文案：History.DynastySpan.eventsEyebrow。"
        )
    }

    static var eventsTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.eventsTitle",
            defaultValue: "关键边界事件",
            comment: "界面文案：History.DynastySpan.eventsTitle。"
        )
    }

    static func subtitle(dynasty: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.subtitle",
            defaultValue: "\(dynasty) · 正统时间线",
            comment: "朝代起讫副标题；参数为朝代简称或名称。"
        )
    }

    static func duration(years: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.duration",
            defaultValue: "国祚 \(years) 年",
            comment: "国祚时长；参数为两边界之间的年数。"
        )
    }
}

public extension CalendarStringKey.History.DynastySpan.Unavailable {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastySpan.unavailable.title",
            defaultValue: "没有找到朝代起讫",
            comment: "界面文案：History.DynastySpan.Unavailable.title。"
        )
    }
}
