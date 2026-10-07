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
            comment: "设置页包含下载模拟与布局预览入口的调试分区标题。"
        )
    }

    static var simulateDownload: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.simulateDownload",
            defaultValue: "模拟完整数据下载",
            comment: "设置页启动完整数据下载进度模拟的操作名称。"
        )
    }

    static var downloadPreview: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview",
            defaultValue: "下载进度布局预览",
            comment: "设置页打开固定下载阶段及布局检查页面的入口名称。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.message",
            defaultValue: "只模拟下载进度，不访问网络、写入文件或替换日历数据库。",
            comment: "设置页调试功能的说明，告知模拟过程不访问网络或修改实际日历数据库。"
        )
    }
}

public extension CalendarStringKey.Settings.Debug.DownloadPreview {
    static var scenariosTab: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.scenariosTab",
            defaultValue: "进度场景",
            comment: "下载布局调试页中切换固定进度场景的标签名称。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.title",
            defaultValue: "下载进度预览",
            comment: "用于检查固定下载进度布局的调试页面标题。"
        )
    }

    static var switchTab: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.switchTab",
            defaultValue: "切换检查",
            comment: "下载布局调试页用于验证切换标签后进度状态的标签名称。"
        )
    }

    static var switchMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.switchMessage",
            defaultValue: "切换标签后，底部应保留当前进度。点击附件可查看完整说明。",
            comment: "下载布局调试页的切换检查说明，提示检查底部进度保留及详情入口。"
        )
    }

    static var sizeTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.sizeTitle",
            defaultValue: "字号",
            comment: "下载布局调试页包含文字大小选择器的分区标题。"
        )
    }

    static var sizePicker: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.sizePicker",
            defaultValue: "Dynamic Type",
            comment: "下载布局调试页的系统文字大小选择器标签。"
        )
    }

    static var defaultSize: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.defaultSize",
            defaultValue: "默认",
            comment: "下载布局调试页的字号选项，表示使用默认字号。"
        )
    }

    static var largeSize: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.largeSize",
            defaultValue: "加大",
            comment: "下载布局调试页的字号选项，表示使用加大的文字尺寸。"
        )
    }

    static var accessibilitySize: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.accessibilitySize",
            defaultValue: "辅助功能最大",
            comment: "下载布局调试页的字号选项，表示使用最大的辅助功能字号。"
        )
    }

    static var stagesTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.stagesTitle",
            defaultValue: "固定下载阶段",
            comment: "下载布局调试页中可手动选择的固定下载阶段分区标题。"
        )
    }

    static var detailsTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.detailsTitle",
            defaultValue: "完整阶段说明",
            comment: "下载布局调试页中完整列出各阶段状态说明的分区标题。"
        )
    }

    static var instructionsTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.instructionsTitle",
            defaultValue: "检查方式",
            comment: "下载布局调试页中展示人工检查指引的分区标题。"
        )
    }

    static var instructions: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.instructions",
            defaultValue: "向下浏览列表可收起标签栏，向上返回可展开。也可旋转设备，检查不同可用宽度。",
            comment: "下载布局调试页的操作指引，说明滚动标签栏和旋转设备的检查方法。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.debug.downloadPreview.message",
            defaultValue: "这里只展示固定进度，不会下载或修改日历数据。",
            comment: "下载布局调试页的说明，告知固定进度展示不会执行真实下载或修改数据。"
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
