import SwiftUI

private struct CalendarBottomStatusBarIsPresentedKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var calendarBottomStatusBarIsPresented: Bool {
        get { self[CalendarBottomStatusBarIsPresentedKey.self] }
        set { self[CalendarBottomStatusBarIsPresentedKey.self] = newValue }
    }
}
