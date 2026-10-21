import SwiftUI

/// 业务提示和导航确认共用一个系统宿主，每次只展示一个 alert。
struct NavigationAlertHost<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
>: ViewModifier {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    let alertContent: (AlertRoute) -> NavigationAlertContent<AlertRoute.Action>?
    let confirmationContent: (NavigationRequest<Scope, Destination>) -> NavigationConfirmationContent?
    let onAction: @MainActor (
        AlertRoute,
        AlertRoute.Action,
        NavigationPresentationContext<Scope, Destination, AlertRoute>
    ) async -> Void

    func body(content: Content) -> some View {
        content.background {
            NavigationSystemAlertHost(alert: alert)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var alert: NavigationSystemAlert? {
        if let node = context.presentedAlert, let copy = alertContent(node.destination) {
            return makeAlert(id: node.id, isConfirmation: false, copy: copy) { action in
                await onAction(node.destination, action, context)
            }
        }
        if let request = context.confirmation, let copy = confirmationContent(request.request) {
            return makeAlert(
                id: request.id, isConfirmation: true,
                copy: NavigationAlertContent(
                    title: copy.title, message: copy.message,
                    firstButton: NavigationAlertButton(copy.confirm, action: true),
                    cancelButton: NavigationAlertCancelButton(copy.cancel, action: false)
                )
            ) { approved in
                if approved {
                    context.confirmNavigation(id: request.id)
                } else {
                    context.cancelNavigation(id: request.id)
                }
            }
        }
        return nil
    }

    private func makeAlert<Action: Hashable>(
        id: UUID, isConfirmation: Bool, copy: NavigationAlertContent<Action>,
        action: @escaping @MainActor (Action) async -> Void
    ) -> NavigationSystemAlert {
        let buttons = copy.presentationButtons
        return NavigationSystemAlert(
            id: id, title: String(localized: copy.title), message: String(localized: copy.message),
            buttons: buttons.map { button in
                NavigationSystemAlert.Button(
                    title: String(localized: button.title),
                    isCancel: button.isCancel, isDestructive: button.isDestructive
                )
            },
            willPresent: { context.alertWillPresent(id: id, isConfirmation: isConfirmation) },
            willDismiss: { context.alertWillDismiss(id: id) },
            didDismiss: { selection in
                // 用独立 Task 等待按钮动作完成，再释放本次 alert 会话；页面重建不会取消这项任务。
                Task { @MainActor in
                    guard context.beginAlertCompletion(id: id) else { return }
                    if let selection, buttons.indices.contains(selection) {
                        await action(buttons[selection].action)
                    }
                    context.alertDidDismiss(id: id)
                }
            }
        )
    }
}
