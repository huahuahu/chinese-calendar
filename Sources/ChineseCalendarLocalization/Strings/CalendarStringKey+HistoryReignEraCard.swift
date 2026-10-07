import Foundation

public extension CalendarStringKey.History {
    enum ReignEraCard {}
}

public extension CalendarStringKey.History.ReignEraCard {
    static func emperor(name: String, title: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraCard.emperor",
            defaultValue: "\(name) · \(title)",
            comment: "年号卡片所属皇帝；参数依次为姓名和庙号/称号。"
        )
    }
}
