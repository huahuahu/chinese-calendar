import Foundation

/// 保存 alert 的文案、按钮和每个按钮要执行的异步操作，供 NavigationSystemAlert 使用。
/// Router 只保存路由；NavigationSystemAlert 的回调保留这些闭包，按钮操作的 Task 执行期间也会保留它们。
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

    /// 用同一个 Action 类型连接按钮内容和处理函数，编译器会检查二者是否匹配。
    /// 为每个按钮保存调用 onAction 的闭包，保留原顺序和取消按钮；初始化时不执行按钮操作。
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
