import SwiftUI

/// A compact month label inside a full-size touch target.
struct LunarMonthButton: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 6
        static let minimumTouchDimension: CGFloat = 44
        static let selectedBackgroundOpacity = 0.12
        static let selectedBorderWidth: CGFloat = 1
    }

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .fixedSize()
                .padding(.horizontal, Constants.horizontalPadding)
                .padding(.vertical, Constants.verticalPadding)
                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                .background(
                    isSelected
                        ? AnyShapeStyle(.tint.opacity(Constants.selectedBackgroundOpacity))
                        : AnyShapeStyle(.quaternary),
                    in: .capsule
                )
                .overlay {
                    Capsule()
                        .strokeBorder(.tint, lineWidth: isSelected ? Constants.selectedBorderWidth : 0)
                }
                // Apply the touch frame after the capsule so the visible button stays compact.
                .frame(
                    minWidth: Constants.minimumTouchDimension,
                    minHeight: Constants.minimumTouchDimension
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
