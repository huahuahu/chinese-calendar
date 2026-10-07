import Foundation

public extension CalendarStringKey.Common {
    enum DatePrecision {}
}

public extension CalendarStringKey.Common.DatePrecision {
    static var year: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.year",
            defaultValue: "年精度",
            comment: "界面文案：Common.DatePrecision.year。"
        )
    }

    static var month: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.month",
            defaultValue: "月精度",
            comment: "界面文案：Common.DatePrecision.month。"
        )
    }

    static var day: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.day",
            defaultValue: "日精度",
            comment: "界面文案：Common.DatePrecision.day。"
        )
    }

    static var range: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.range",
            defaultValue: "范围精度",
            comment: "界面文案：Common.DatePrecision.range。"
        )
    }

    static var unknown: LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.unknown",
            defaultValue: "精度未知",
            comment: "界面文案：Common.DatePrecision.unknown。"
        )
    }

    static func indexed(precision: String, index: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.indexed",
            defaultValue: "\(precision) · index \(index, format: .number.grouping(.never))",
            comment: "来源日期精度与索引；参数依次为精度名称和不加千位分隔的连续索引。"
        )
    }

    static func bounds(lower: String, upper: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.bounds",
            defaultValue: "范围精度 · \(lower) 到 \(upper)",
            comment: "不确定日期区间；参数依次为下界与上界的精度和索引。"
        )
    }

    static func bound(precision: String, index: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "common.datePrecision.bound",
            defaultValue: "\(precision) \(index, format: .number.grouping(.never))",
            comment: "单个日期边界；参数依次为精度名称和连续索引。"
        )
    }
}
