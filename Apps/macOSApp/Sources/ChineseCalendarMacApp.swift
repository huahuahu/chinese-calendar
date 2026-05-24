import ChineseCalendarLogging
import ChineseCalendarPersistence
import ChineseCalendarUI
import SwiftUI

@main
struct ChineseCalendarMacApp: App {
    init() {
        ChineseCalendarLog.app.notice("Launching macOS app")
    }

    var body: some Scene {
        WindowGroup {
            CalendarHomeView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .modelContainer(ChineseCalendarModelContainerFactory.sharedContainer)
    }
}
