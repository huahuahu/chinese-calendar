import Foundation

public extension CalendarStringKey.Store {
    enum Download {}
}

public extension CalendarStringKey.Store.Download {
    enum Banner {}
    enum Completed {}
    enum Downloading {}
    enum Installing {}
    enum Preparing {}
    enum Progress {}
    enum Step {}
    enum Validating {}

    static var failureTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.failureTitle",
            defaultValue: "完整数据下载失败",
            comment: "完整日期数据下载失败时的错误提示标题。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.title",
            defaultValue: "完整数据下载",
            comment: "展示完整日期数据下载、校验及安装过程的详情页面标题。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Banner {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.banner.title",
            defaultValue: "可下载完整日期数据",
            comment: "日历只使用基础数据时，提示可下载完整日期数据的横幅标题。"
        )
    }

    static var action: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.banner.action",
            defaultValue: "下载",
            comment: "完整数据下载提示横幅中启动下载的按钮名称。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Completed {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.title",
            defaultValue: "完成",
            comment: "下载详情阶段列表中表示整个流程结束的阶段标题。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.detail",
            defaultValue: "现在可以浏览每日干支和对应民用日期。",
            comment: "完整数据安装成功后的说明，提示现在可浏览逐日干支与对应民用日期。"
        )
    }

    static var summary: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.summary",
            defaultValue: "完整日历数据已就绪",
            comment: "完整数据下载流程成功结束时的状态摘要。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.shortTitle",
            defaultValue: "已就绪",
            comment: "底部紧凑下载进度中表示全部数据已可用的简短状态标题。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Downloading {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.downloading.title",
            defaultValue: "下载文件",
            comment: "下载详情中正在传输完整数据文件的阶段标题。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.downloading.shortTitle",
            defaultValue: "下载",
            comment: "底部紧凑下载进度中正在传输文件的简短阶段标题。"
        )
    }

    static func detail(progress: Double) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.downloading.detail",
            defaultValue: "文件已下载 \(progress, format: .percent.precision(.fractionLength(0)))。",
            comment: "文件传输进度说明；第一个参数为 0 到 1 的下载比例，显示为整数百分比。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Installing {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.installing.title",
            defaultValue: "安装数据",
            comment: "下载详情中安装完整日期数据的阶段标题。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.installing.detail",
            defaultValue: "正在安装完整日历数据。",
            comment: "下载详情中解释当前正在将完整数据安装到本地存储的状态说明。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.installing.shortTitle",
            defaultValue: "安装",
            comment: "底部紧凑下载进度中安装文件的简短阶段标题。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Preparing {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.preparing.title",
            defaultValue: "准备下载",
            comment: "下载详情中准备下载地址与文件信息的阶段标题。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.preparing.detail",
            defaultValue: "正在准备下载所需的信息。",
            comment: "下载详情中解释当前正在获取下载所需信息的状态说明。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.preparing.shortTitle",
            defaultValue: "准备",
            comment: "底部紧凑下载进度中准备下载信息的简短阶段标题。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Progress {
    static var accessibilityHint: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.progress.accessibilityHint",
            defaultValue: "查看完整下载状态",
            comment: "底部下载进度入口的无障碍提示，说明激活后会打开完整状态详情。"
        )
    }

    static var inputLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.progress.inputLabel",
            defaultValue: "下载进度",
            comment: "底部下载进度控件的无障碍输入名称，供语音控制定位。"
        )
    }

    static var detailInputLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.progress.detailInputLabel",
            defaultValue: "查看下载状态",
            comment: "下载进度详情入口的无障碍输入名称，供语音控制定位。"
        )
    }

    static func stage(step: Int, count: Int, title: LocalizedStringResource) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.progress.stage",
            defaultValue: "第 \(step)/\(count) 步 · \(title)",
            comment: "下载进度标题；参数依次为当前步骤序号、步骤总数和已本地化的阶段名称。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Step {
    static var completed: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.step.completed",
            defaultValue: "已完成",
            comment: "下载详情阶段列表中，已完成步骤的状态标记。"
        )
    }

    static var pending: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.step.pending",
            defaultValue: "等待开始",
            comment: "下载详情阶段列表中，尚未开始步骤的状态标记。"
        )
    }

    static var current: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.step.current",
            defaultValue: "进行中",
            comment: "下载详情阶段列表中，当前正在执行步骤的状态标记。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Validating {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.validating.title",
            defaultValue: "校验文件",
            comment: "下载详情中检查下载文件完整性的阶段标题。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.validating.detail",
            defaultValue: "正在确认下载文件完整。",
            comment: "下载详情中解释当前正在检查文件完整性的状态说明。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.validating.shortTitle",
            defaultValue: "校验",
            comment: "底部紧凑下载进度中检查文件完整性的简短阶段标题。"
        )
    }
}
