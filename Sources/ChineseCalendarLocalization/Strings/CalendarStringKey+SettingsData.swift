import Foundation

public extension CalendarStringKey.Settings {
    enum Data {}
}

public extension CalendarStringKey.Settings.Data {
    enum Base {}
    enum Downloading {}
    enum Full {}
    enum Preparing {}
    enum Recovery {}

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.title",
            defaultValue: "数据",
            comment: "设置页展示数据安装状态及清空操作的分区标题。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Base {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.base.title",
            defaultValue: "正在使用内置基础数据",
            comment: "设置页数据状态标题，表示当前正在使用内置年份和月份资料。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.base.message",
            defaultValue: "没有已安装的完整日期数据；仍可清理未完成的下载缓存。",
            comment: "设置页正在使用基础数据时，说明仍可清理未完成下载留下的缓存。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Downloading {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.downloading.title",
            defaultValue: "完整数据下载中",
            comment: "设置页数据状态标题，表示完整日期数据正在下载。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.downloading.message",
            defaultValue: "清空会取消当前下载，并删除已经保存的临时文件。",
            comment: "设置页下载进行中的说明，告知清空操作会取消下载并删除临时文件。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Full {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.full.title",
            defaultValue: "已安装完整日期数据",
            comment: "设置页数据状态标题，表示完整日期数据已经可用。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.full.message",
            defaultValue: "清空后会回到基础数据，日级记录需要重新下载完整数据后才能浏览。",
            comment: "设置页完整日期数据状态的说明，告知清空后逐日浏览需要重新下载。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Preparing {
    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.preparing.message",
            defaultValue: "日历数据准备完成后可以清理下载缓存。",
            comment: "设置页准备数据期间的说明，告知准备完成后可以清理缓存。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Recovery {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.recovery.title",
            defaultValue: "日历数据需要恢复",
            comment: "设置页数据状态标题，表示当前日历数据需要恢复。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.recovery.message",
            defaultValue: "可以尝试清空下载数据并恢复内置基础数据。",
            comment: "设置页数据异常时的恢复建议，提示可清空下载数据并回到内置基础数据。"
        )
    }
}
