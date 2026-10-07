import Foundation

public extension CalendarStringKey.History {
    enum ReignEraList {}
}

public extension CalendarStringKey.History.ReignEraList {
    enum Empty {}

    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraList.title",
            defaultValue: "年号",
            comment: "展示某朝代年号及其使用区间的列表页面标题。"
        )
    }

    static func count(count: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraList.count",
            defaultValue: "\(count) 个年号",
            comment: "年号列表摘要；参数为年号数量。"
        )
    }

    static func summary(count: Int, boundary: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraList.summary",
            defaultValue: "\(count) 个年号 · \(boundary)",
            comment: "年号列表摘要；参数依次为年号数量和朝代起讫日期。"
        )
    }
}

public extension CalendarStringKey.History.ReignEraList.Empty {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraList.empty.title",
            defaultValue: "没有年号资料",
            comment: "朝代年号列表没有记录时的空状态标题。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.reignEraList.empty.message",
            defaultValue: "当前 store 中没有这个朝代的年号记录。",
            comment: "朝代年号列表为空时，解释当前存储没有该朝代的年号记录。"
        )
    }
}
