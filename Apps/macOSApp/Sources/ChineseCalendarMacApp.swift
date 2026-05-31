import ChineseCalendarLogging
import ChineseCalendarUI
import SwiftUI

@main
struct ChineseCalendarMacApp: App {
    @State private var storeCoordinator = ChineseCalendarStoreCoordinator()

    init() {
        ChineseCalendarLog.app.notice("Launching macOS app")
    }

    var body: some Scene {
        WindowGroup {
            ChineseCalendarRootView(coordinator: storeCoordinator)
                .frame(minWidth: 960, minHeight: 640)
        }

        Window("完整数据下载进度", id: FullStoreDownloadProgressWindow.sceneID) {
            FullStoreDownloadProgressWindow(coordinator: storeCoordinator)
        }
        .defaultSize(width: 420, height: 220)

        Settings {
            CalendarSettingsView(coordinator: storeCoordinator)
                .scenePadding()
                .frame(width: 420)
        }
    }
}
