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
            comment: "界面文案：Settings.Data.title。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Base {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.base.title",
            defaultValue: "正在使用内置基础数据",
            comment: "界面文案：Settings.Data.Base.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.base.message",
            defaultValue: "没有已安装的完整日期数据；仍可清理未完成的下载缓存。",
            comment: "界面文案：Settings.Data.Base.message。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Downloading {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.downloading.title",
            defaultValue: "完整数据下载中",
            comment: "界面文案：Settings.Data.Downloading.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.downloading.message",
            defaultValue: "清空会取消当前下载，并删除已经保存的临时文件。",
            comment: "界面文案：Settings.Data.Downloading.message。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Full {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.full.title",
            defaultValue: "已安装完整日期数据",
            comment: "界面文案：Settings.Data.Full.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.full.message",
            defaultValue: "清空后会回到基础数据，日级记录需要重新下载完整数据后才能浏览。",
            comment: "界面文案：Settings.Data.Full.message。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Preparing {
    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.preparing.message",
            defaultValue: "日历数据准备完成后可以清理下载缓存。",
            comment: "界面文案：Settings.Data.Preparing.message。"
        )
    }
}

public extension CalendarStringKey.Settings.Data.Recovery {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.recovery.title",
            defaultValue: "日历数据需要恢复",
            comment: "界面文案：Settings.Data.Recovery.title。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.data.recovery.message",
            defaultValue: "可以尝试清空下载数据并恢复内置基础数据。",
            comment: "界面文案：Settings.Data.Recovery.message。"
        )
    }
}
