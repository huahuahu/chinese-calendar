import SwiftUI

enum CalendarColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "calendarColorSchemePreference"

    var id: Self {
        self
    }

    var title: String {
        switch self {
        case .system:
            "跟随系统"
        case .light:
            "浅色"
        case .dark:
            "深色"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

struct CalendarColorSchemePreferenceModifier: ViewModifier {
    @AppStorage(CalendarColorSchemePreference.storageKey)
    private var colorSchemePreference = CalendarColorSchemePreference.system

    func body(content: Content) -> some View {
        content.preferredColorScheme(colorSchemePreference.colorScheme)
    }
}

extension View {
    func calendarColorSchemePreference() -> some View {
        modifier(CalendarColorSchemePreferenceModifier())
    }
}
