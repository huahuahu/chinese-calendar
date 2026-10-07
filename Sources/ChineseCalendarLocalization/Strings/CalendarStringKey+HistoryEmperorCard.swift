import Foundation

public extension CalendarStringKey.History {
    enum EmperorCard {}
}

public extension CalendarStringKey.History.EmperorCard {
    static var unknownReign: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorCard.unknownReign",
            defaultValue: "在位时间待考",
            comment: "皇帝卡片缺少在位区间资料时的占位说明。"
        )
    }

    static func twoReignsDuration(years: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorCard.twoReignsDuration",
            defaultValue: "两度在位 · \(years) 年",
            comment: "两段在位的时长；参数为合计年数。"
        )
    }

    static func multipleReignsDuration(count: Int, years: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorCard.multipleReignsDuration",
            defaultValue: "\(count) 段在位 · \(years) 年",
            comment: "多段在位的时长；参数依次为段数和合计年数。"
        )
    }

    static func eraNamesAccessibilityLabel(names: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorCard.eraNamesAccessibilityLabel",
            defaultValue: "年号：\(names)",
            comment: "年号标签组朗读；参数为本地化连接的年号名称列表。"
        )
    }

    static func accessibilityIntroduction(sequence: String, name: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.emperorCard.accessibilityIntroduction",
            defaultValue: "第 \(sequence) 位，\(name)",
            comment: "皇帝卡片朗读开头；参数依次为列表序号和姓名。"
        )
    }
}
