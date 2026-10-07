import Foundation

public extension CalendarStringKey.Store {
    enum Bootstrap {}
}

public extension CalendarStringKey.Store.Bootstrap {
    static var preparing: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.bootstrap.preparing",
            defaultValue: "正在准备日历数据",
            comment: "App 启动准备日历存储期间的加载状态说明。"
        )
    }

    static var failureTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "store.bootstrap.failureTitle",
            defaultValue: "无法打开日历数据",
            comment: "App 启动时无法打开日历存储的错误页面标题。"
        )
    }
}
