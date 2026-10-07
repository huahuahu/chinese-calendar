import Foundation

public extension CalendarStringKey.History {
    enum ReignEraDetail {}
}

public extension CalendarStringKey.History.ReignEraDetail {
    enum Unavailable {}

    static var emperorTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.emperorTitle",
            defaultValue: "所属皇帝",
            comment: "界面文案：History.ReignEraDetail.emperorTitle。"
        )
    }

    static var boundaryEyebrow: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.boundaryEyebrow",
            defaultValue: "使用区间",
            comment: "界面文案：History.ReignEraDetail.boundaryEyebrow。"
        )
    }

    static var boundaryTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.boundaryTitle",
            defaultValue: "纪年边界",
            comment: "界面文案：History.ReignEraDetail.boundaryTitle。"
        )
    }

    static var notesEyebrow: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.notesEyebrow",
            defaultValue: "沿革说明",
            comment: "界面文案：History.ReignEraDetail.notesEyebrow。"
        )
    }

    static var notesTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.notesTitle",
            defaultValue: "年号交接",
            comment: "界面文案：History.ReignEraDetail.notesTitle。"
        )
    }

    static var noteSeal: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.noteSeal",
            defaultValue: "记",
            comment: "界面文案：History.ReignEraDetail.noteSeal。"
        )
    }

    static func emperorSequence(dynasty: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.emperorSequence",
            defaultValue: "\(dynasty)朝皇帝序列",
            comment: "所属皇帝卡片副标题；参数为朝代简称。"
        )
    }

    static func subtitle(dynasty: String, number: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.subtitle",
            defaultValue: "\(dynasty) · 第 \(number) 个年号",
            comment: "年号详情副标题；参数依次为朝代名和从 1 开始的年号序号。"
        )
    }
}

public extension CalendarStringKey.History.ReignEraDetail.Unavailable {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.unavailable.title",
            defaultValue: "没有找到年号",
            comment: "界面文案：History.ReignEraDetail.Unavailable.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.unavailable.message",
            defaultValue: "这个年号记录不在当前 SwiftData store 中。",
            comment: "界面文案：History.ReignEraDetail.Unavailable.message。"
        )
    }
}
