import Foundation

public extension CalendarStringKey.Debug {
    enum Split {}
}

public extension CalendarStringKey.Debug.Split {
    static var title: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.title",
            defaultValue: "分栏导航测试",
            comment: "调试操作中打开原生分栏导航示例的入口和示例页标题。"
        )
    }

    static var ordinary: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.ordinary",
            defaultValue: "普通栈",
            comment: "分栏导航调试的混合标签页中，使用普通导航栈的标签名称。"
        )
    }

    static var twoColumn: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.twoColumn",
            defaultValue: "两栏",
            comment: "分栏导航调试中打开两栏示例的入口和标签名称。"
        )
    }

    static var threeColumn: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.threeColumn",
            defaultValue: "三栏",
            comment: "分栏导航调试中打开三栏示例的入口和标签名称。"
        )
    }

    static var mixedTabs: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.mixedTabs",
            defaultValue: "混合 Tab",
            comment: "分栏导航调试中打开普通栈、两栏和三栏混合标签页示例的入口。"
        )
    }

    static var openSheet: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.openSheet",
            defaultValue: "以弹窗打开",
            comment: "分栏导航调试中以弹窗展示分栏示例的按钮。"
        )
    }

    static var openFullScreen: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.openFullScreen",
            defaultValue: "以全屏打开",
            comment: "分栏导航调试中以全屏模态展示分栏示例的按钮。"
        )
    }

    static var categories: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.categories",
            defaultValue: "示例分类",
            comment: "三栏导航调试中前栏的分类列表标题，分类仅用于演示。"
        )
    }

    static var items: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.items",
            defaultValue: "示例对象",
            comment: "分栏导航调试中待选择的对象列表标题，对象仅用于演示。"
        )
    }

    static var firstCategory: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.firstCategory",
            defaultValue: "分类一",
            comment: "三栏导航调试中第一个虚构分类的名称，不表示真实历史分类。"
        )
    }

    static var secondCategory: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.secondCategory",
            defaultValue: "分类二",
            comment: "三栏导航调试中第二个虚构分类的名称，不表示真实历史分类。"
        )
    }

    static var firstItem: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.firstItem",
            defaultValue: "对象一",
            comment: "分栏导航调试中第一个虚构对象的名称，不表示真实历史数据。"
        )
    }

    static var secondItem: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.secondItem",
            defaultValue: "对象二",
            comment: "分栏导航调试中第二个虚构对象的名称，不表示真实历史数据。"
        )
    }

    static var thirdItem: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.thirdItem",
            defaultValue: "对象三",
            comment: "分栏导航调试中第三个虚构对象的名称，不表示真实历史数据。"
        )
    }

    static var fourthItem: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.fourthItem",
            defaultValue: "对象四",
            comment: "分栏导航调试中第四个虚构对象的名称，不表示真实历史数据。"
        )
    }

    static var emptyTitle: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.emptyTitle",
            defaultValue: "请选择对象",
            comment: "分栏导航调试中尚未选中对象时，详情栏空状态的标题。"
        )
    }

    static var emptyMessage: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.emptyMessage",
            defaultValue: "从前面的列表选择一个对象，再继续查看子详情。",
            comment: "分栏导航调试中详情栏空状态的说明，引导从前栏或中间栏选择对象。"
        )
    }

    static var chooseCategory: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.chooseCategory",
            defaultValue: "请选择分类",
            comment: "三栏导航调试中尚未选择分类时，中间栏空状态的标题。"
        )
    }

    static var retainDetail: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.retainDetail",
            defaultValue: "切换分类时保留详情",
            comment: "三栏导航调试中控制切换分类后是否保留当前对象详情的开关。"
        )
    }

    static var clearSelection: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.clearSelection",
            defaultValue: "清除详情",
            comment: "分栏导航调试中清除当前对象选择并返回详情空状态的按钮。"
        )
    }

    static var repeatSelection: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.repeatSelection",
            defaultValue: "再次选择当前对象",
            comment: "分栏导航调试中重复选择同一对象，用于检查详情路径是否保留的按钮。"
        )
    }

    static var nextItem: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.nextItem",
            defaultValue: "选择下一个对象",
            comment: "分栏导航调试中切换到下一个示例对象，用于检查详情路径是否清空的按钮。"
        )
    }

    static var showDetail: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.showDetail",
            defaultValue: "显示详情栏",
            comment: "分栏导航调试中请求窄屏展示详情栏的按钮。"
        )
    }

    static var showSidebar: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.showSidebar",
            defaultValue: "显示前栏",
            comment: "分栏导航调试中请求窄屏展示前栏的按钮。"
        )
    }

    static var showAllColumns: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.showAllColumns",
            defaultValue: "显示所有栏",
            comment: "分栏导航调试中请求展示全部栏目，用于检查系统适配行为的按钮。"
        )
    }

    static var push: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.push",
            defaultValue: "查看下一层详情",
            comment: "分栏导航调试中向当前对象的详情路径继续压入一个子页面的按钮。"
        )
    }

    static var selection: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.selection",
            defaultValue: "当前详情",
            comment: "分栏导航调试中显示当前选中对象名称的状态字段标题。"
        )
    }

    static var layout: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.layout",
            defaultValue: "布局状态",
            comment: "分栏导航调试中展示当前窄屏栏目与栏目可见性的状态分组标题。"
        )
    }

    static var compactColumn: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.compactColumn",
            defaultValue: "窄屏当前栏",
            comment: "分栏导航调试中显示窄屏当前优先展示栏目的状态字段标题。"
        )
    }

    static var sidebar: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.sidebar",
            defaultValue: "前栏",
            comment: "分栏导航调试布局状态中表示前栏的选项名称。"
        )
    }

    static var content: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.content",
            defaultValue: "中间栏",
            comment: "三栏导航调试布局状态中表示中间栏的选项名称。"
        )
    }

    static var detail: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.detail",
            defaultValue: "详情栏",
            comment: "分栏导航调试布局状态中表示对象详情栏的选项名称。"
        )
    }

    static var visibility: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.visibility",
            defaultValue: "栏目可见性",
            comment: "分栏导航调试中显示或选择栏目可见性模式的字段标题。"
        )
    }

    static var automatic: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.automatic",
            defaultValue: "自动",
            comment: "分栏导航调试栏目可见性中，由系统自动决定可见栏目的选项名称。"
        )
    }

    static var allColumns: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.allColumns",
            defaultValue: "所有栏",
            comment: "分栏导航调试栏目可见性中，请求显示所有栏目的选项名称。"
        )
    }

    static var doubleColumn: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.doubleColumn",
            defaultValue: "后两栏",
            comment: "三栏导航调试栏目可见性中，请求显示中间栏和详情栏的选项名称。"
        )
    }

    static var detailOnly: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.detailOnly",
            defaultValue: "仅详情",
            comment: "分栏导航调试栏目可见性中，请求只显示详情栏的选项名称。"
        )
    }

    static var message: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.message",
            defaultValue: "前栏选择由 App 管理，详情路径由 NavigationCore 管理。切换对象清空路径，重复选择保留路径。",
            comment: "分栏导航调试页说明对象选择与详情路径的管理职责及切换行为。"
        )
    }

    static var root: LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.root",
            defaultValue: "详情根页",
            comment: "分栏导航调试中表示当前对象详情路径尚未压入子页面的页面标题。"
        )
    }

    static func level(_ value: Int) -> LocalizedStringResource {
        CalendarStringKey.resource(
            "debug.split.level",
            defaultValue: "子详情第 \(value, format: .number.grouping(.never)) 层",
            comment: "分栏导航调试中子详情页面的标题；参数为从一开始且不加千位分隔的详情层数。"
        )
    }
}
