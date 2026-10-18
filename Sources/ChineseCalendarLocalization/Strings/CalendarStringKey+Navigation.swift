import Foundation

public extension CalendarStringKey {
    enum Navigation {}
}

public extension CalendarStringKey.Navigation {
    static var confirmTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.confirmTitle",
            defaultValue: "离开当前页面？",
            comment: "收到外部链接时，请用户确认是否离开当前模态流程的提示标题。"
        )
    }

    static var continueAction: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.continueAction",
            defaultValue: "关闭并前往",
            comment: "确认关闭当前模态流程并打开外部链接目标的按钮。"
        )
    }

    static var stayAction: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.stayAction",
            defaultValue: "留在当前页面",
            comment: "取消外部导航并保留当前页面的按钮。"
        )
    }

    static var dynastyTarget: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.dynastyTarget",
            defaultValue: "链接中的朝代详情",
            comment: "外部导航确认中描述朝代详情目标。"
        )
    }

    static var emperorTarget: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.emperorTarget",
            defaultValue: "链接中的皇帝详情",
            comment: "外部导航确认中描述皇帝详情目标。"
        )
    }

    static var linkTarget: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.linkTarget",
            defaultValue: "链接中的页面",
            comment: "外部导航确认中描述其他页面目标。"
        )
    }

    static var openSheet: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.openSheet",
            defaultValue: "在弹窗中打开",
            comment: "历史资料入口的上下文菜单，使用独立模态流程浏览资料。"
        )
    }

    static var openFullScreen: LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.openFullScreen",
            defaultValue: "全屏打开",
            comment: "历史资料入口的上下文菜单，以全屏模态流程浏览资料。"
        )
    }

    static func confirmMessage(target: String) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "navigation.confirmMessage",
            defaultValue: "将关闭当前弹出页面及其子页面，前往\(target)。",
            comment: "外部导航确认说明；参数为目标页面的本地化描述。"
        )
    }
}
