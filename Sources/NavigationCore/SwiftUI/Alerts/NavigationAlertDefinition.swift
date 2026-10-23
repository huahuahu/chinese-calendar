import Foundation

/// 宿主配置将提示内容与同类型动作处理配对后，交给系统宿主执行。
/// 路由仍由 Router 保存；这里的业务闭包仅由 View 宿主和当前系统提示持有。
@MainActor
public struct NavigationAlertDefinition {
    struct Button {
        let title: LocalizedStringResource
        let isCancel: Bool
        let isDestructive: Bool
        let perform: @MainActor () async -> Void
    }

    let title: LocalizedStringResource
    let message: LocalizedStringResource
    let buttons: [Button]

    /// 在同一个泛型边界检查内容与动作匹配，再擦除为无参数异步操作。
    /// 保留内容已经确定的顺序、去重结果及独立取消入口；构造时不执行业务。
    public init<Action: Hashable>(
        content: NavigationAlertContent<Action>,
        onAction: @escaping @MainActor (Action) async -> Void
    ) {
        title = content.title
        message = content.message
        buttons = content.presentationButtons.map { button in
            Button(
                title: button.title,
                isCancel: button.isCancel,
                isDestructive: button.isDestructive,
                perform: { await onAction(button.action) }
            )
        }
    }
}
