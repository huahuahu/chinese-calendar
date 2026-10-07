import Foundation

public extension CalendarStringKey.Store {
    enum Error {}
}

public extension CalendarStringKey.Store.Error {
    static var prepare: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.prepare",
            defaultValue: "无法读取日历数据，请重试；如果问题持续，请重新打开 App。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var download: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.download",
            defaultValue: "无法完成完整数据下载，请稍后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var clear: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.clear",
            defaultValue: "无法清空已下载数据，请稍后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var network: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.network",
            defaultValue: "无法连接下载服务，请检查网络连接后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var timedOut: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.timedOut",
            defaultValue: "下载连接超时，请稍后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var storage: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.storage",
            defaultValue: "设备存储空间不足，请释放空间后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var permission: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.permission",
            defaultValue: "无法访问日历数据文件，请重新打开 App 后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var missingResource: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.missingResource",
            defaultValue: "内置日历数据缺失，请重新安装 App 后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var missingContainer: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.missingContainer",
            defaultValue: "无法访问日历数据存储位置，请重新打开 App 后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var incompatible: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.incompatible",
            defaultValue: "下载数据与当前 App 版本不兼容，请更新 App 后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var invalidManifest: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.invalidManifest",
            defaultValue: "下载信息无效，请稍后重试。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var invalidFile: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.invalidFile",
            defaultValue: "下载文件不完整或校验失败，请重新下载。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static var expiredDownload: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.expiredDownload",
            defaultValue: "下载缓存已经失效，请重新下载。",
            comment: "日历数据操作失败时的用户提示与恢复建议；不暴露内部文件路径或诊断错误。"
        )
    }

    static func server(status: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "store.error.server",
            defaultValue: "下载服务暂时不可用（HTTP \(status, format: .number.grouping(.never))），请稍后重试。",
            comment: "服务端下载失败；参数为 HTTP 状态码，不加千位分隔。"
        )
    }
}
