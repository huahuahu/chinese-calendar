import Foundation

public extension CalendarStringKey.Settings {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "settings.title",
            defaultValue: "设置",
            comment: "设置 Tab 及其根页面的导航标题。"
        )
    }
}
