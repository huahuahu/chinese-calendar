import Foundation

public extension CalendarStringKey.History {
    enum DynastyDetail {}
}

public extension CalendarStringKey.History.DynastyDetail {
    enum Fact {}
    enum Unavailable {}
}

public extension CalendarStringKey.History.DynastyDetail.Fact {
    static var emperorUnit: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.emperorUnit",
            defaultValue: "位皇帝",
            comment: "朝代详情皇帝数量事实卡中，紧随数量展示的计数单位。"
        )
    }

    static var reignEraUnit: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.reignEraUnit",
            defaultValue: "个年号",
            comment: "朝代详情年号数量事实卡中，紧随数量展示的计数单位。"
        )
    }

    static var yearUnit: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.yearUnit",
            defaultValue: "年",
            comment: "朝代详情国祚时长事实卡中，紧随年数展示的时间单位。"
        )
    }

    static func emperorsAccessibilityLabel(dynasty: String, count: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.emperorsAccessibilityLabel",
            defaultValue: "查看\(dynasty)朝 \(count) 位皇帝",
            comment: "皇帝入口朗读；参数依次为朝代简称和皇帝人数。"
        )
    }

    static func reignErasAccessibilityLabel(dynasty: String, count: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.reignErasAccessibilityLabel",
            defaultValue: "查看\(dynasty)朝 \(count) 个年号",
            comment: "年号入口朗读；参数依次为朝代简称和年号数量。"
        )
    }

    static func spanAccessibilityLabel(dynasty: String, years: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.spanAccessibilityLabel",
            defaultValue: "查看\(dynasty)朝国祚与起讫，共 \(years) 年",
            comment: "国祚入口朗读；参数依次为朝代简称和国祚年数。"
        )
    }

    static func unknownSpanAccessibilityLabel(dynasty: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.unknownSpanAccessibilityLabel",
            defaultValue: "查看\(dynasty)朝国祚与起讫，国祚暂无",
            comment: "国祚资料不全的入口朗读；参数为朝代简称。"
        )
    }
}

public extension CalendarStringKey.History.DynastyDetail.Unavailable {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.unavailable.title",
            defaultValue: "没有找到朝代",
            comment: "朝代详情无法找到目标记录时的不可用状态标题。"
        )
    }

    static var periodMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.unavailable.periodMessage",
            defaultValue: "对应的朝代或正统期记录不在当前 SwiftData store 中。",
            comment: "按正统时期进入朝代详情但关联记录不存在时，解释内容不可用的原因。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.unavailable.message",
            defaultValue: "这个朝代记录不在当前 SwiftData store 中。",
            comment: "按朝代进入详情但记录不存在时，解释内容不可用的原因。"
        )
    }
}
