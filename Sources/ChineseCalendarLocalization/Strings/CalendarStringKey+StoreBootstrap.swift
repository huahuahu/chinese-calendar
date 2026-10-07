import Foundation

public extension CalendarStringKey.Store {
    enum Bootstrap {}
}

public extension CalendarStringKey.Store.Bootstrap {
    static var preparing: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.bootstrap.preparing",
            defaultValue: "正在准备日历数据",
            comment: "界面文案：Store.Bootstrap.preparing。"
        )
    }

    static var failureTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.bootstrap.failureTitle",
            defaultValue: "无法打开日历数据",
            comment: "界面文案：Store.Bootstrap.failureTitle。"
        )
    }
}
