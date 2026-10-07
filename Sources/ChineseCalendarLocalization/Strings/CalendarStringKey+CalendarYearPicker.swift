import Foundation

public extension CalendarStringKey.Calendar {
    enum YearPicker {}
}

public extension CalendarStringKey.Calendar.YearPicker {
    enum Century {}

    static var accessibilityHint: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.yearPicker.accessibilityHint",
            defaultValue: "打开年份选择器",
            comment: "日历年份入口的无障碍提示，说明激活后会打开年份选择器。"
        )
    }

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.yearPicker.title",
            defaultValue: "年份选择器",
            comment: "用于跳转到指定农历年的年份选择页面标题。"
        )
    }
}

public extension CalendarStringKey.Calendar.YearPicker.Century {
    static func beforeCommonEra(century: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.yearPicker.century.beforeCommonEra",
            defaultValue: "公元前 \(century) 世纪",
            comment: "年份选择器分区标题；参数为没有 0 世纪的正整数世纪序号。"
        )
    }

    static func commonEra(century: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.yearPicker.century.commonEra",
            defaultValue: "公元 \(century) 世纪",
            comment: "年份选择器分区标题；参数为没有 0 世纪的正整数世纪序号。"
        )
    }

    static func beforeCommonEraIndex(century: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "calendar.yearPicker.century.beforeCommonEraIndex",
            defaultValue: "前\(century)",
            comment: "年份选择器侧边索引；参数为公元前的正整数世纪序号。"
        )
    }
}
