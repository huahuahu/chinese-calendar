import Foundation

public extension CalendarStringKey.Common {
    enum Error {}
}

public extension CalendarStringKey.Common.Error {
    static var retryLater: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.error.retryLater",
            defaultValue: "请稍后再试。",
            comment: "界面文案：Common.Error.retryLater。"
        )
    }
}
