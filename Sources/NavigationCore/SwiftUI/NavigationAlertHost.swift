import SwiftUI

/// 业务提示和导航确认共用一个系统宿主，每次只展示一个 alert。
struct NavigationAlertHost<Scope: Hashable, Destination: Hashable, AlertRoute: NavigationAlertRoute>: ViewModifier {
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
                    buttons: [
                        NavigationAlertButton(copy.cancel, action: false, role: .cancel),
                        NavigationAlertButton(copy.confirm, action: true)
                    ]
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
        NavigationSystemAlert(
            id: id, title: String(localized: copy.title), message: String(localized: copy.message),
            buttons: copy.buttons.map { button in
                NavigationSystemAlert.Button(
                    title: String(localized: button.title),
                    isCancel: button.role == .cancel, isDestructive: button.role == .destructive
                )
            },
            willPresent: { context.alertWillPresent(id: id, isConfirmation: isConfirmation) },
            willDismiss: { context.alertWillDismiss(id: id) },
            didDismiss: { selection in
                // 生命周期归属本次呈现，不随业务页面 body 重建而取消。
                Task { @MainActor in
                    guard context.beginAlertCompletion(id: id) else { return }
                    if let selection, copy.buttons.indices.contains(selection) {
                        await action(copy.buttons[selection].action)
                    }
                    context.alertDidDismiss(id: id)
                }
            }
        )
    }
}
