#if os(iOS)
    import SwiftUI

    struct CalendarTabViewBottomAccessoryModifier<Accessory: View>: ViewModifier {
        let isEnabled: Bool
        let accessory: () -> Accessory

        func body(content: Content) -> some View {
            if #available(iOS 26.1, *) {
                content.tabViewBottomAccessory(isEnabled: isEnabled, content: accessory)
            } else if isEnabled {
                content.tabViewBottomAccessory(content: accessory)
            } else {
                content
            }
        }
    }

    extension View {
        func calendarTabViewBottomAccessory(
            isEnabled: Bool,
            @ViewBuilder content: @escaping () -> some View
        ) -> some View {
            modifier(
                CalendarTabViewBottomAccessoryModifier(
                    isEnabled: isEnabled,
                    accessory: content
                )
            )
        }
    }
#endif
