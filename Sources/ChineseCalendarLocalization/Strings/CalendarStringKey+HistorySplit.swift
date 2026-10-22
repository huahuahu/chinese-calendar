import Foundation

public extension CalendarStringKey.History {
    enum Split {}
}

public extension CalendarStringKey.History.Split {
    static var chooseDynastyTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.split.chooseDynastyTitle",
            defaultValue: "选择朝代",
            comment: "历史分栏页面尚未选择朝代时，资料入口栏的空状态标题。"
        )
    }

    static var chooseDynastyMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.split.chooseDynastyMessage",
            defaultValue: "从正统时间线选择一个朝代，查看相关资料。",
            comment: "历史分栏页面尚未选择朝代时，引导用户从正统时间线选择朝代。"
        )
    }

    static var chooseContentTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.split.chooseContentTitle",
            defaultValue: "选择历史资料",
            comment: "历史分栏页面尚未选择资料入口时，详情栏的空状态标题。"
        )
    }

    static var chooseContentMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "history.split.chooseContentMessage",
            defaultValue: "选择皇帝、年号或正统时间，查看详细内容。",
            comment: "历史分栏页面尚未选择资料入口时，引导用户选择要查看的资料类别。"
        )
    }
}
