import ChineseCalendarPersistence
import ChineseCalendarUI
import SwiftUI

@main
struct ChineseCalendariOSApp: App {
    var body: some Scene {
        WindowGroup {
            CalendarHomeView()
        }
        .modelContainer(ChineseCalendarModelContainerFactory.sharedContainer)
    }
}
