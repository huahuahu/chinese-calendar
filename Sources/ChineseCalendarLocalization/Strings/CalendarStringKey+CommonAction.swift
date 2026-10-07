import Foundation

public extension CalendarStringKey.Common {
    enum Action {}
}

public extension CalendarStringKey.Common.Action {
    static var ok: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.ok",
            defaultValue: "好",
            comment: "界面文案：Common.Action.ok。"
        )
    }

    static var retry: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.retry",
            defaultValue: "重试",
            comment: "界面文案：Common.Action.retry。"
        )
    }

    static var close: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.close",
            defaultValue: "关闭",
            comment: "界面文案：Common.Action.close。"
        )
    }

    static var done: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.done",
            defaultValue: "完成",
            comment: "界面文案：Common.Action.done。"
        )
    }
}
