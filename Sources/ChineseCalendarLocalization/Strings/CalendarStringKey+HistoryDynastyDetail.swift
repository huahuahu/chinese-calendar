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
            comment: "界面文案：History.DynastyDetail.Fact.emperorUnit。"
        )
    }

    static var reignEraUnit: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.reignEraUnit",
            defaultValue: "个年号",
            comment: "界面文案：History.DynastyDetail.Fact.reignEraUnit。"
        )
    }

    static var yearUnit: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.fact.yearUnit",
            defaultValue: "年",
            comment: "界面文案：History.DynastyDetail.Fact.yearUnit。"
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
            comment: "界面文案：History.DynastyDetail.Unavailable.title。"
        )
    }

    static var periodMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.unavailable.periodMessage",
            defaultValue: "对应的朝代或正统期记录不在当前 SwiftData store 中。",
            comment: "界面文案：History.DynastyDetail.Unavailable.periodMessage。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.dynastyDetail.unavailable.message",
            defaultValue: "这个朝代记录不在当前 SwiftData store 中。",
            comment: "界面文案：History.DynastyDetail.Unavailable.message。"
        )
    }
}
