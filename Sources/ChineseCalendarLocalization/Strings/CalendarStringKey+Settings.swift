import Foundation

public extension CalendarStringKey.Settings {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.title",
            defaultValue: "设置",
            comment: "界面文案：Settings.title。"
        )
    }
}
