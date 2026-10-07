import Foundation

public extension CalendarStringKey.Store {
    enum ContentLevel {}
}

public extension CalendarStringKey.Store.ContentLevel {
    static var base: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.contentLevel.base",
            defaultValue: "基础数据",
            comment: "界面文案：Store.ContentLevel.base。"
        )
    }

    static var full: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.contentLevel.full",
            defaultValue: "完整日期数据",
            comment: "界面文案：Store.ContentLevel.full。"
        )
    }
}
