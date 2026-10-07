import Foundation

public extension CalendarStringKey.Settings {
    enum ClearData {}
}

public extension CalendarStringKey.Settings.ClearData {
    static var progress: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.progress",
            defaultValue: "正在清空",
            comment: "界面文案：Settings.ClearData.progress。"
        )
    }

    static var action: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.action",
            defaultValue: "清空已下载数据",
            comment: "界面文案：Settings.ClearData.action。"
        )
    }

    static var confirmationTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.confirmationTitle",
            defaultValue: "清空已下载数据？",
            comment: "界面文案：Settings.ClearData.confirmationTitle。"
        )
    }

    static var confirmationMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.confirmationMessage",
            defaultValue: "这会取消正在进行的完整数据下载，删除下载缓存，并恢复到内置基础日历数据。",
            comment: "界面文案：Settings.ClearData.confirmationMessage。"
        )
    }

    static var successTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.successTitle",
            defaultValue: "已清空",
            comment: "界面文案：Settings.ClearData.successTitle。"
        )
    }

    static var successMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.successMessage",
            defaultValue: "已删除下载数据，并恢复到内置基础日历数据。",
            comment: "界面文案：Settings.ClearData.successMessage。"
        )
    }

    static var failureTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.failureTitle",
            defaultValue: "清空失败",
            comment: "界面文案：Settings.ClearData.failureTitle。"
        )
    }
}
