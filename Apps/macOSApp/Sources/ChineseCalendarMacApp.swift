import ChineseCalendarUI
import SwiftUI

@main
struct ChineseCalendarMacApp: App {
    var body: some Scene {
        WindowGroup {
            CalendarHomeView()
                .frame(minWidth: 960, minHeight: 640)
        }
    }
}
