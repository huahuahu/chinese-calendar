import Foundation

public extension CalendarStringKey.Debug {
    enum Alert {}
}

public extension CalendarStringKey.Debug.Alert {
    static var show: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.show",
            defaultValue: "显示业务 Alert",
            comment: "导航调试中展示一个业务提示，提示结束前保留当前页面。"
        )
    }

    static var queue: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.queue",
            defaultValue: "连续显示两个 Alert",
            comment: "导航调试中依次展示两个提示，用于验证提示不会重叠。"
        )
    }

    static var navigateWhilePresented: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.navigateWhilePresented",
            defaultValue: "Alert 期间请求跳转历史",
            comment: "导航调试中先显示业务提示并提交跨标签页请求，验证关闭顺序。"
        )
    }

    static var navigationChoice: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.navigationChoice",
            defaultValue: "从 Alert 按钮跳转",
            comment: "导航调试中展示带跳转按钮的提示，用于验证按钮执行与关闭顺序。"
        )
    }

    static var noticeMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.noticeMessage",
            defaultValue: "这是业务提示。关闭它后，才会处理等待中的提示或导航请求。",
            comment: "导航调试业务提示的说明，说明后续请求的等待规则。"
        )
    }

    static var navigationTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.navigationTitle",
            defaultValue: "前往历史页面？",
            comment: "导航调试中通过提示按钮发起跳转的标题。"
        )
    }

    static var navigationMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.navigationMessage",
            defaultValue: "确认后先关闭这个提示，再前往历史标签页。",
            comment: "导航调试中说明按钮跳转的关闭顺序。"
        )
    }

    static func noticeTitle(number: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.alert.noticeTitle",
            defaultValue: "业务提示 \(number)",
            comment: "导航调试业务提示的标题；参数为提示序号，用于检查连续提示的顺序。"
        )
    }
}
