import SwiftUI

/// 业务提示和导航确认共用一个系统宿主，每次只展示一个 alert。
struct NavigationAlertHost<
    Scope: NavigationScope,
    Destination: NavigationDestination,
    AlertRoute: NavigationAlertRoute
>: ViewModifier {
    let context: NavigationPresentationContext<Scope, Destination, AlertRoute>
    let alertDefinition: (AlertRoute) -> NavigationAlertDefinition?
    let confirmationContent: (NavigationRequest<Scope, Destination>) -> NavigationConfirmationContent?

    func body(content: Content) -> some View {
        content.background {
            NavigationSystemAlertHost(alert: alert)
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    private var alert: NavigationSystemAlert? {
        if let node = context.presentedAlert, let definition = alertDefinition(node.destination) {
            return NavigationSystemAlert(id: .business(node.id), definition: definition, context: context)
        }
        if let request = context.confirmation, let copy = confirmationContent(request.request) {
            let definition = NavigationAlertDefinition(
                content: NavigationAlertContent(
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
            return NavigationSystemAlert(id: .confirmation(request.id), definition: definition, context: context)
        }
        return nil
    }
}
