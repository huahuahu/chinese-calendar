import Foundation

public extension CalendarStringKey.Store {
    enum ContentLevel {}
}

public extension CalendarStringKey.Store.ContentLevel {
    static var base: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.contentLevel.base",
            defaultValue: "基础数据",
            comment: "数据层级的显示名称，表示只包含年份和月份的内置资料。"
        )
    }

    static var full: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.contentLevel.full",
            defaultValue: "完整日期数据",
            comment: "数据层级的显示名称，表示包含可逐日浏览的完整日期资料。"
        )
    }
}
