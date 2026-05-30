import ChineseCalendarLogging
import ChineseCalendarUI
import SwiftUI

@main
struct ChineseCalendarMacApp: App {
    init() {
        ChineseCalendarLog.app.notice("Launching macOS app")
    }

    var body: some Scene {
        WindowGroup {
            ChineseCalendarRootView()
                .frame(minWidth: 960, minHeight: 640)
        }
    }
}
