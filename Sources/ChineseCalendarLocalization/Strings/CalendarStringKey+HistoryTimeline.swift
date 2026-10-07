import Foundation

public extension CalendarStringKey.History {
    enum Timeline {}
}

public extension CalendarStringKey.History.Timeline {
    enum Empty {}

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.title",
            defaultValue: "朝代",
            comment: "界面文案：History.Timeline.title。"
        )
    }

    static var subtitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.subtitle",
            defaultValue: "沿正统时间线，进入一个朝代的纪年体系",
            comment: "界面文案：History.Timeline.subtitle。"
        )
    }

    static var listTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.listTitle",
            defaultValue: "朝代序列",
            comment: "界面文案：History.Timeline.listTitle。"
        )
    }

    static var sortLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.sortLabel",
            defaultValue: "按起始年代",
            comment: "界面文案：History.Timeline.sortLabel。"
        )
    }
}

public extension CalendarStringKey.History.Timeline.Empty {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.empty.title",
            defaultValue: "没有可显示的朝代",
            comment: "界面文案：History.Timeline.Empty.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.empty.message",
            defaultValue: "当前 store 没有默认正统传统的时间线记录。",
            comment: "界面文案：History.Timeline.Empty.message。"
        )
    }
}
