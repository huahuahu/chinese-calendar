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
            comment: "界面文案：History.EmperorList.title。"
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
            comment: "界面文案：History.EmperorList.Empty.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorList.empty.message",
            defaultValue: "当前 store 中没有这个朝代的皇帝记录。",
            comment: "界面文案：History.EmperorList.Empty.message。"
        )
    }
}
