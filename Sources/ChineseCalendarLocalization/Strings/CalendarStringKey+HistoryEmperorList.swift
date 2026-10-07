import Foundation

public extension CalendarStringKey.History {
    enum EmperorList {}
}

public extension CalendarStringKey.History.EmperorList {
    enum Empty {}

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorList.title",
            defaultValue: "帝王",
            comment: "展示某朝代皇帝与在位记录的列表页面标题。"
        )
    }

    static func summary(emperorCount: Int, segmentCount: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorList.summary",
            defaultValue: "\(emperorCount) 位皇帝 · \(segmentCount) 段纪年",
            comment: "皇帝列表摘要；参数依次为人数和在位区间数。"
        )
    }
}

public extension CalendarStringKey.History.EmperorList.Empty {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorList.empty.title",
            defaultValue: "没有帝王资料",
            comment: "朝代帝王列表没有记录时的空状态标题。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorList.empty.message",
            defaultValue: "当前 store 中没有这个朝代的皇帝记录。",
            comment: "朝代帝王列表为空时，解释当前存储没有该朝代的皇帝记录。"
        )
    }
}
