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
            comment: "年号详情中展示使用该年号的皇帝的分区标题。"
        )
    }

    static var boundaryEyebrow: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.boundaryEyebrow",
            defaultValue: "使用区间",
            comment: "年号详情日期边界区域的辅助栏目标签，表示年号使用范围。"
        )
    }

    static var boundaryTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.boundaryTitle",
            defaultValue: "纪年边界",
            comment: "年号详情中展示启用与结束时间的边界分区标题。"
        )
    }

    static var notesEyebrow: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.notesEyebrow",
            defaultValue: "沿革说明",
            comment: "年号详情来源备注区域的辅助栏目标签。"
        )
    }

    static var notesTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.notesTitle",
            defaultValue: "年号交接",
            comment: "年号详情中解释沿用、交接等来源备注的分区标题。"
        )
    }

    static var noteSeal: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.noteSeal",
            defaultValue: "记",
            comment: "年号交接说明旁的单字装饰印记，表示此处有资料备注。"
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
            comment: "年号详情无法找到目标记录时的不可用状态标题。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraDetail.unavailable.message",
            defaultValue: "这个年号记录不在当前 SwiftData store 中。",
            comment: "年号详情记录不存在时，解释当前存储缺少该年号资料。"
        )
    }
}
