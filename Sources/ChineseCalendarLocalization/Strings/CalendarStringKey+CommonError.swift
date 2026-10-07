import Foundation

public extension CalendarStringKey.Common {
    enum Error {}
}

public extension CalendarStringKey.Common.Error {
    static var retryLater: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.error.retryLater",
            defaultValue: "请稍后再试。",
            comment: "可恢复错误提示中的通用建议，表示稍后再次尝试当前操作。"
        )
    }
}
