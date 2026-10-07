import Foundation

public extension CalendarStringKey.Settings {
    enum Unavailable {}
}

public extension CalendarStringKey.Settings.Unavailable {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.unavailable.title",
            defaultValue: "无法打开设置",
            comment: "设置页面暂时无法打开时的不可用状态标题。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.unavailable.message",
            defaultValue: "当前日历数据尚未准备完成。",
            comment: "设置页面因数据尚未准备完成而不可用时的原因说明。"
        )
    }
}
