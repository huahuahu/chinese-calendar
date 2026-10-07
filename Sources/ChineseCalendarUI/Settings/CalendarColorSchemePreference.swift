import ChineseCalendarLocalization
import SwiftUI

enum CalendarColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    static let storageKey = "calendarColorSchemePreference"

    var id: Self {
        self
    }

    var title: LocalizedStringResource {
        switch self {
        case .system:
            CalendarStringKey.Settings.Appearance.system
        case .light:
            CalendarStringKey.Settings.Appearance.light
        case .dark:
            CalendarStringKey.Settings.Appearance.dark
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
