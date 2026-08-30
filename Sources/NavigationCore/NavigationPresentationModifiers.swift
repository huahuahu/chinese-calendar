import SwiftUI

public extension View {
    func navigationFullScreenCover<Item: Identifiable>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss, content: content)
    }
}
