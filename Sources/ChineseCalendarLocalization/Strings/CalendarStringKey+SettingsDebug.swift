import Foundation

public extension CalendarStringKey.Settings {
    enum Debug {}
}

public extension CalendarStringKey.Settings.Debug {
    enum DownloadPreview {}

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.title",
            defaultValue: "调试",
            comment: "界面文案：Settings.Debug.title。"
        )
    }

    static var simulateDownload: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.simulateDownload",
            defaultValue: "模拟完整数据下载",
            comment: "界面文案：Settings.Debug.simulateDownload。"
        )
    }

    static var downloadPreview: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview",
            defaultValue: "下载进度布局预览",
            comment: "界面文案：Settings.Debug.downloadPreview。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.message",
            defaultValue: "只模拟下载进度，不访问网络、写入文件或替换日历数据库。",
            comment: "界面文案：Settings.Debug.message。"
        )
    }
}

public extension CalendarStringKey.Settings.Debug.DownloadPreview {
    static var scenariosTab: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.scenariosTab",
            defaultValue: "进度场景",
            comment: "界面文案：Settings.Debug.DownloadPreview.scenariosTab。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.title",
            defaultValue: "下载进度预览",
            comment: "界面文案：Settings.Debug.DownloadPreview.title。"
        )
    }

    static var switchTab: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.switchTab",
            defaultValue: "切换检查",
            comment: "界面文案：Settings.Debug.DownloadPreview.switchTab。"
        )
    }

    static var switchMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.switchMessage",
            defaultValue: "切换标签后，底部应保留当前进度。点击附件可查看完整说明。",
            comment: "界面文案：Settings.Debug.DownloadPreview.switchMessage。"
        )
    }

    static var sizeTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.sizeTitle",
            defaultValue: "字号",
            comment: "界面文案：Settings.Debug.DownloadPreview.sizeTitle。"
        )
    }

    static var sizePicker: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.sizePicker",
            defaultValue: "Dynamic Type",
            comment: "界面文案：Settings.Debug.DownloadPreview.sizePicker。"
        )
    }

    static var defaultSize: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.defaultSize",
            defaultValue: "默认",
            comment: "界面文案：Settings.Debug.DownloadPreview.defaultSize。"
        )
    }

    static var largeSize: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.largeSize",
            defaultValue: "加大",
            comment: "界面文案：Settings.Debug.DownloadPreview.largeSize。"
        )
    }

    static var accessibilitySize: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.accessibilitySize",
            defaultValue: "辅助功能最大",
            comment: "界面文案：Settings.Debug.DownloadPreview.accessibilitySize。"
        )
    }

    static var stagesTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.stagesTitle",
            defaultValue: "固定下载阶段",
            comment: "界面文案：Settings.Debug.DownloadPreview.stagesTitle。"
        )
    }

    static var detailsTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.detailsTitle",
            defaultValue: "完整阶段说明",
            comment: "界面文案：Settings.Debug.DownloadPreview.detailsTitle。"
        )
    }

    static var instructionsTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.instructionsTitle",
            defaultValue: "检查方式",
            comment: "界面文案：Settings.Debug.DownloadPreview.instructionsTitle。"
        )
    }

    static var instructions: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.instructions",
            defaultValue: "向下浏览列表可收起标签栏，向上返回可展开。也可旋转设备，检查不同可用宽度。",
            comment: "界面文案：Settings.Debug.DownloadPreview.instructions。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.message",
            defaultValue: "这里只展示固定进度，不会下载或修改日历数据。",
            comment: "界面文案：Settings.Debug.DownloadPreview.message。"
        )
    }

    static var downloadStarted: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.downloadStarted",
            defaultValue: "下载（0%）",
            comment: "调试页固定文件传输阶段；百分比为模拟值。"
        )
    }

    static var downloading: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.downloading",
            defaultValue: "下载（50%）",
            comment: "调试页固定文件传输阶段；百分比为模拟值。"
        )
    }

    static var downloadFinished: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.downloadFinished",
            defaultValue: "下载（100%，尚未校验）",
            comment: "调试页固定文件传输阶段；百分比为模拟值。"
        )
    }
}
