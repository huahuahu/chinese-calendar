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
            comment: "历史 Tab 及朝代时间线首页的导航标题。"
        )
    }

    static var subtitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.subtitle",
            defaultValue: "沿正统时间线，进入一个朝代的纪年体系",
            comment: "历史首页导航说明，引导用户沿正统时间线进入朝代纪年资料。"
        )
    }

    static var listTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.listTitle",
            defaultValue: "朝代序列",
            comment: "历史首页按时间浏览朝代的列表分区标题。"
        )
    }

    static var sortLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.sortLabel",
            defaultValue: "按起始年代",
            comment: "历史首页朝代列表的排序说明，表示以起始年代排列。"
        )
    }
}

public extension CalendarStringKey.History.Timeline.Empty {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.empty.title",
            defaultValue: "没有可显示的朝代",
            comment: "历史首页没有可展示的朝代时间线时的空状态标题。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.timeline.empty.message",
            defaultValue: "当前 store 没有默认正统传统的时间线记录。",
            comment: "历史首页时间线为空时，解释当前存储没有默认正统传统的记录。"
        )
    }
}
