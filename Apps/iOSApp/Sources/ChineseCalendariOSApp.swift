import ChineseCalendarLogging
import ChineseCalendarPersistence
import ChineseCalendarUI
import SwiftUI

@main
struct ChineseCalendariOSApp: App {
    init() {
        ChineseCalendarLog.app.notice("Launching iOS app")
    }

    var body: some Scene {
        WindowGroup {
            CalendarHomeView()
        }
        .modelContainer(ChineseCalendarModelContainerFactory.sharedContainer)
    }
}
