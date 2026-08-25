import SwiftUI

/// Hosts a presented destination in its own navigation stack and recursively presents child nodes.
public struct NavigationPresentationNodeView<Destination: Hashable, DestinationContent: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable private var node: NavigationPresentationNode<Destination>
    private let onChildDismiss: () -> Void
    private let destinationContent: (Destination, @escaping () -> Void) -> DestinationContent

    public init(
        node: NavigationPresentationNode<Destination>,
        onChildDismiss: @escaping () -> Void = {},
        @ViewBuilder destinationContent: @escaping (Destination, @escaping () -> Void) -> DestinationContent
    ) {
        self.node = node
        self.onChildDismiss = onChildDismiss
        self.destinationContent = destinationContent
    }

    public var body: some View {
        NavigationStack(path: $node.path) {
            destinationContent(node.destination) {
                dismiss()
            }
            .navigationDestination(for: Destination.self) { destination in
                destinationContent(destination) {
                    dismiss()
                }
            }
        }
        .sheet(item: $node.sheet, onDismiss: onChildDismiss) { child in
            NavigationPresentationNodeView(
                node: child,
                onChildDismiss: onChildDismiss,
                destinationContent: destinationContent
            )
        }
        .navigationFullScreenCover(item: $node.fullScreen, onDismiss: onChildDismiss) { child in
            NavigationPresentationNodeView(
                node: child,
                onChildDismiss: onChildDismiss,
                destinationContent: destinationContent
            )
        }
    }
}
