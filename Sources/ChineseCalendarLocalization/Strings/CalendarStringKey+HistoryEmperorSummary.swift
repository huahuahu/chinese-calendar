import Foundation

public extension CalendarStringKey.History {
    enum EmperorSummary {}
}

public extension CalendarStringKey.History.EmperorSummary {
    static var missingNames: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorSummary.missingNames",
            defaultValue: "未记录别名",
            comment: "皇帝摘要缺少来源中其他姓名或称号时的占位说明。"
        )
    }

    static func subtitle(names: String, segments: Int, eras: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorSummary.subtitle",
            defaultValue: "\(names) · \(segments) 段在位 · \(eras) 个年号",
            comment: "皇帝摘要；参数依次为本名/庙号/称号列表、在位段数、年号数量。"
        )
    }
}
