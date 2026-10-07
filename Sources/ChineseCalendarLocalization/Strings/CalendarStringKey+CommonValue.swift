import Foundation

public extension CalendarStringKey.Common {
    enum Value {}
}

public extension CalendarStringKey.Common.Value {
    static var unavailable: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.value.unavailable",
            defaultValue: "-",
            comment: "缺失日期的简短占位符。"
        )
    }

    static var empty: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.value.empty",
            defaultValue: "",
            comment: "没有可呈现的状态时使用的空值，不向用户朗读。"
        )
    }
}
