import Foundation

public extension CalendarStringKey {
    enum Debug {}
}

public extension CalendarStringKey.Debug {
    enum Navigation {}

    static var actions: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.actions",
            defaultValue: "调试操作",
            comment: "设置页 Debug 分区中打开调试动作菜单的按钮与无障碍名称。"
        )
    }

    static var downloadActions: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.downloadActions",
            defaultValue: "下载调试",
            comment: "调试操作菜单中包含下载进度模拟和布局预览的分组名称。"
        )
    }
}

public extension CalendarStringKey.Debug.Navigation {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.title",
            defaultValue: "导航测试",
            comment: "调试操作中的导航分组名称与导航测试页标题。"
        )
    }

    static var localActions: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.localActions",
            defaultValue: "当前层导航",
            comment: "导航测试中作用于当前 Tab 或当前模态的操作分组标题。"
        )
    }

    static var push: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.push",
            defaultValue: "Push 新测试页",
            comment: "在当前作用域的导航路径中压入一个新导航测试页的按钮。"
        )
    }

    static var sheet: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.sheet",
            defaultValue: "Sheet 打开测试页",
            comment: "在当前作用域上以弹窗展示新导航测试页的按钮，可重复嵌套。"
        )
    }

    static var fullScreen: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.fullScreen",
            defaultValue: "全屏打开测试页",
            comment: "在当前作用域上以全屏模态展示新导航测试页的按钮。"
        )
    }

    static var mainTabsSheet: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.mainTabsSheet",
            defaultValue: "Sheet 打开主标签页",
            comment: "导航调试菜单中以弹窗展示独立主标签页的按钮，用于验证各呈现层的标签和导航路径互不影响。"
        )
    }

    static var mainTabsFullScreen: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.mainTabsFullScreen",
            defaultValue: "全屏打开主标签页",
            comment: "导航调试菜单中以全屏模态展示独立主标签页的按钮，可在主标签页模态内再次打开。"
        )
    }

    static var returnActions: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.returnActions",
            defaultValue: "返回与关闭",
            comment: "导航测试中返回上一个栈页面与关闭当前模态的操作分组标题。"
        )
    }

    static var pop: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.pop",
            defaultValue: "Pop 返回上一页",
            comment: "移除当前作用域路径的最后一页；路径为空时禁用。"
        )
    }

    static var dismiss: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.dismiss",
            defaultValue: "关闭当前模态",
            comment: "关闭当前模态及其子层；位于 Tab 导航栈时禁用。"
        )
    }

    static var externalActions: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.externalActions",
            defaultValue: "跨 Tab 与外部链接",
            comment: "导航测试中由根 Router 协调跨标签页与外部链接的操作分组标题。"
        )
    }

    static var pushOnHistory: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.pushOnHistory",
            defaultValue: "在历史 Tab Push 测试页",
            comment: "切换到历史标签页并压入新导航测试页；有模态时先确认关闭。"
        )
    }

    static var deepLink: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.deepLink",
            defaultValue: "模拟打开今年的 Deep Link",
            comment: "模拟日历业务收到今年链接；有模态时触发离开确认，无模态时直接前往。"
        )
    }

    static var scope: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.scope",
            defaultValue: "当前作用域",
            comment: "导航测试页展示当前导航作用域的字段标题。"
        )
    }

    static var pathDepth: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.pathDepth",
            defaultValue: "当前层 Push 页数",
            comment: "导航测试页展示当前作用域路径长度的字段标题，不包含模态根页。"
        )
    }

    static var pageIdentity: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.pageIdentity",
            defaultValue: "页面 ID",
            comment: "导航测试页展示路由携带的唯一标识，便于核对返回后是否保留原页面。"
        )
    }

    static var rootScope: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.rootScope",
            defaultValue: "根作用域",
            comment: "导航测试页表示当前使用根 Router 上下文的状态文字。"
        )
    }

    static var modalScope: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.modalScope",
            defaultValue: "模态作用域",
            comment: "导航测试页表示当前处于独立模态导航上下文的状态文字。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.navigation.message",
            defaultValue: "每次打开生成新的页面 ID。Push 和返回只改变当前层，关闭模态回到父层。可连续打开弹窗或全屏页，再模拟 Deep Link 检查取消与整层关闭。",
            comment: "导航测试页说明如何使用页面标识和操作检查作用域、嵌套模态及外部导航。"
        )
    }
}
