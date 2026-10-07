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
            comment: "界面文案：Store.Download.failureTitle。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.title",
            defaultValue: "完整数据下载",
            comment: "界面文案：Store.Download.title。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Banner {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.banner.title",
            defaultValue: "可下载完整日期数据",
            comment: "界面文案：Store.Download.Banner.title。"
        )
    }

    static var action: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.banner.action",
            defaultValue: "下载",
            comment: "界面文案：Store.Download.Banner.action。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Completed {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.title",
            defaultValue: "完成",
            comment: "界面文案：Store.Download.Completed.title。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.detail",
            defaultValue: "现在可以浏览每日干支和对应民用日期。",
            comment: "界面文案：Store.Download.Completed.detail。"
        )
    }

    static var summary: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.summary",
            defaultValue: "完整日历数据已就绪",
            comment: "界面文案：Store.Download.Completed.summary。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.completed.shortTitle",
            defaultValue: "已就绪",
            comment: "界面文案：Store.Download.Completed.shortTitle。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Downloading {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.downloading.title",
            defaultValue: "下载文件",
            comment: "界面文案：Store.Download.Downloading.title。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.downloading.shortTitle",
            defaultValue: "下载",
            comment: "界面文案：Store.Download.Downloading.shortTitle。"
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
            comment: "界面文案：Store.Download.Installing.title。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.installing.detail",
            defaultValue: "正在安装完整日历数据。",
            comment: "界面文案：Store.Download.Installing.detail。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.installing.shortTitle",
            defaultValue: "安装",
            comment: "界面文案：Store.Download.Installing.shortTitle。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Preparing {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.preparing.title",
            defaultValue: "准备下载",
            comment: "界面文案：Store.Download.Preparing.title。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.preparing.detail",
            defaultValue: "正在准备下载所需的信息。",
            comment: "界面文案：Store.Download.Preparing.detail。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.preparing.shortTitle",
            defaultValue: "准备",
            comment: "界面文案：Store.Download.Preparing.shortTitle。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Progress {
    static var accessibilityHint: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.progress.accessibilityHint",
            defaultValue: "查看完整下载状态",
            comment: "界面文案：Store.Download.Progress.accessibilityHint。"
        )
    }

    static var inputLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.progress.inputLabel",
            defaultValue: "下载进度",
            comment: "界面文案：Store.Download.Progress.inputLabel。"
        )
    }

    static var detailInputLabel: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.progress.detailInputLabel",
            defaultValue: "查看下载状态",
            comment: "界面文案：Store.Download.Progress.detailInputLabel。"
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
            comment: "界面文案：Store.Download.Step.completed。"
        )
    }

    static var pending: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.step.pending",
            defaultValue: "等待开始",
            comment: "界面文案：Store.Download.Step.pending。"
        )
    }

    static var current: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.step.current",
            defaultValue: "进行中",
            comment: "界面文案：Store.Download.Step.current。"
        )
    }
}

public extension CalendarStringKey.Store.Download.Validating {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.validating.title",
            defaultValue: "校验文件",
            comment: "界面文案：Store.Download.Validating.title。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.validating.detail",
            defaultValue: "正在确认下载文件完整。",
            comment: "界面文案：Store.Download.Validating.detail。"
        )
    }

    static var shortTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.download.validating.shortTitle",
            defaultValue: "校验",
            comment: "界面文案：Store.Download.Validating.shortTitle。"
        )
    }
}
