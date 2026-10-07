import Foundation

public extension CalendarStringKey.Settings {
    enum Unavailable {}
}

public extension CalendarStringKey.Settings.Unavailable {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.unavailable.title",
            defaultValue: "无法打开设置",
            comment: "界面文案：Settings.Unavailable.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.unavailable.message",
            defaultValue: "当前日历数据尚未准备完成。",
            comment: "界面文案：Settings.Unavailable.message。"
        )
    }
}
