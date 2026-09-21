import SwiftUI

/// 为朝代流程的整行导航入口提供统一、无需动画的按压反馈。
struct HistoryPressButtonStyle: ButtonStyle {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let defaultCornerRadius: CGFloat = 18
        static let pressedTintOpacity: Double = 0.12
    }

    var cornerRadius: CGFloat = Constants.defaultCornerRadius

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                if configuration.isPressed {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.tint.opacity(Constants.pressedTintOpacity))
                }
            }
            .contentShape(.rect(cornerRadius: cornerRadius))
    }
}
