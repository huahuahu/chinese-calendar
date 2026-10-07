import Foundation

public extension CalendarStringKey.History {
    enum EmperorDetail {}
}

public extension CalendarStringKey.History.EmperorDetail {
    enum Unavailable {}

    static var dynastyLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.dynastyLabel",
            defaultValue: "朝代",
            comment: "界面文案：History.EmperorDetail.dynastyLabel。"
        )
    }

    static var reignLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.reignLabel",
            defaultValue: "在位",
            comment: "界面文案：History.EmperorDetail.reignLabel。"
        )
    }

    static var reignErasTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.reignErasTitle",
            defaultValue: "年号",
            comment: "界面文案：History.EmperorDetail.reignErasTitle。"
        )
    }

    static var namesTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.namesTitle",
            defaultValue: "称号",
            comment: "界面文案：History.EmperorDetail.namesTitle。"
        )
    }

    static var personalNameLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.personalNameLabel",
            defaultValue: "本名",
            comment: "界面文案：History.EmperorDetail.personalNameLabel。"
        )
    }

    static var templeNameLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.templeNameLabel",
            defaultValue: "庙号",
            comment: "界面文案：History.EmperorDetail.templeNameLabel。"
        )
    }

    static var posthumousNameLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.posthumousNameLabel",
            defaultValue: "谥号/称号",
            comment: "界面文案：History.EmperorDetail.posthumousNameLabel。"
        )
    }

    static var segmentsTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.segmentsTitle",
            defaultValue: "在位区间",
            comment: "界面文案：History.EmperorDetail.segmentsTitle。"
        )
    }

    static func segmentCount(count: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.segmentCount",
            defaultValue: "\(count) 段",
            comment: "皇帝在位区间数量；参数为段数。"
        )
    }

    static func eraCount(count: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.eraCount",
            defaultValue: "\(count) 个",
            comment: "皇帝年号数量；参数为个数。"
        )
    }

    static func segmentTitle(number: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.segmentTitle",
            defaultValue: "第 \(number) 段在位",
            comment: "在位区间标题；参数为从 1 开始的区间序号。"
        )
    }
}

public extension CalendarStringKey.History.EmperorDetail.Unavailable {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.unavailable.title",
            defaultValue: "没有找到皇帝",
            comment: "界面文案：History.EmperorDetail.Unavailable.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorDetail.unavailable.message",
            defaultValue: "这个皇帝记录不在当前 SwiftData store 中。",
            comment: "界面文案：History.EmperorDetail.Unavailable.message。"
        )
    }
}
