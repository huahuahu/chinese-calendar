import Foundation

public extension CalendarStringKey.Settings {
    enum Appearance {}
}

public extension CalendarStringKey.Settings.Appearance {
    static var system: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.system",
            defaultValue: "跟随系统",
            comment: "设置页颜色模式选项，表示使用系统当前的外观设置。"
        )
    }

    static var light: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.light",
            defaultValue: "浅色",
            comment: "设置页颜色模式选项，表示始终使用浅色外观。"
        )
    }

    static var dark: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.dark",
            defaultValue: "深色",
            comment: "设置页颜色模式选项，表示始终使用深色外观。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.title",
            defaultValue: "外观",
            comment: "设置页包含颜色模式选择器的外观分区标题。"
        )
    }

    static var pickerLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.appearance.pickerLabel",
            defaultValue: "颜色模式",
            comment: "设置页用于选择跟随系统、浅色或深色外观的控件标签。"
        )
    }
}
