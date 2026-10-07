import Foundation

public extension CalendarStringKey.Common {
    enum Action {}
}

public extension CalendarStringKey.Common.Action {
    static var ok: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.ok",
            defaultValue: "好",
            comment: "提示弹窗中确认已知晓信息并关闭弹窗的通用按钮名称。"
        )
    }

    static var retry: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.retry",
            defaultValue: "重试",
            comment: "可恢复错误状态中重新执行失败操作的通用按钮名称。"
        )
    }

    static var close: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.close",
            defaultValue: "关闭",
            comment: "用于关闭当前弹出页面或详情的通用按钮名称。"
        )
    }

    static var done: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.action.done",
            defaultValue: "完成",
            comment: "用于结束当前操作并离开临时页面的通用按钮名称。"
        )
    }
}
