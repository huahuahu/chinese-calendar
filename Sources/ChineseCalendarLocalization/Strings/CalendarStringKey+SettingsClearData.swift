import Foundation

public extension CalendarStringKey.Settings {
    enum ClearData {}
}

public extension CalendarStringKey.Settings.ClearData {
    static var progress: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.progress",
            defaultValue: "正在清空",
            comment: "设置页正在清空下载数据时的操作状态文字。"
        )
    }

    static var action: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.action",
            defaultValue: "清空已下载数据",
            comment: "设置页发起删除已下载日期数据及缓存的操作名称。"
        )
    }

    static var confirmationTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.confirmationTitle",
            defaultValue: "清空已下载数据？",
            comment: "设置页执行清空下载数据前的确认弹窗标题。"
        )
    }

    static var confirmationMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.confirmationMessage",
            defaultValue: "这会取消正在进行的完整数据下载，删除下载缓存，并恢复到内置基础日历数据。",
            comment: "清空下载数据前的确认说明，告知会取消下载、删除缓存并恢复内置基础数据。"
        )
    }

    static var successTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.successTitle",
            defaultValue: "已清空",
            comment: "设置页清空下载数据成功时的结果弹窗标题。"
        )
    }

    static var successMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.successMessage",
            defaultValue: "已删除下载数据，并恢复到内置基础日历数据。",
            comment: "清空操作成功后的结果说明，告知已恢复为内置基础数据。"
        )
    }

    static var failureTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.clearData.failureTitle",
            defaultValue: "清空失败",
            comment: "设置页清空下载数据失败时的结果弹窗标题。"
        )
    }
}
