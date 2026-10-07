import Foundation

public extension CalendarStringKey.Settings {
    enum Appearance {}
}

public extension CalendarStringKey.Settings.Appearance {
    static var system: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.system",
            defaultValue: "跟随系统",
            comment: "界面文案：Settings.Appearance.system。"
        )
    }

    static var light: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.light",
            defaultValue: "浅色",
            comment: "界面文案：Settings.Appearance.light。"
        )
    }

    static var dark: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.dark",
            defaultValue: "深色",
            comment: "界面文案：Settings.Appearance.dark。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.title",
            defaultValue: "外观",
            comment: "界面文案：Settings.Appearance.title。"
        )
    }

    static var pickerLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.pickerLabel",
            defaultValue: "颜色模式",
            comment: "界面文案：Settings.Appearance.pickerLabel。"
        )
    }
}
