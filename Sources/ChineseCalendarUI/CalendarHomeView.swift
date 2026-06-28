import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import Foundation
import SwiftData
import SwiftUI

public struct CalendarHomeView: View {
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]
    @State private var router = CalendarRouter()
    @State private var didOpenColdLaunchDeepLink = false
    private let openSettings: (() -> Void)?

    public init(openSettings: (() -> Void)? = nil) {
        self.openSettings = openSettings
    }

    @available(*, deprecated, message: "CalendarHomeView now selects the current lunar year automatically.")
    public init(selectedDate _: ChineseCalendarDate?) {
        self.init()
    }

    public var body: some View {
        @Bindable var router = router

        Group {
            #if os(iOS)
                CalendarHomeTabView(
                    router: router,
                    years: years,
                    emptyStateDescription: emptyStateDescription,
                    openSettings: openSettings
                )
            #else
                CalendarHomeSplitView(
                    router: router,
                    years: years,
                    emptyStateDescription: emptyStateDescription
                )
            #endif
        }
        .sheet(item: $router.sheet, onDismiss: router.applyDeferredDeepLinkIfReady) { node in
            CalendarPresentationNodeView(node: node, years: years) {
                router.dismissSheet()
            }
        }
        .calendarFullScreenCover(item: $router.fullScreen, onDismiss: router.applyDeferredDeepLinkIfReady) { node in
            CalendarPresentationNodeView(node: node, years: years) {
                router.dismissFullScreen()
            }
        }
        .task {
            openColdLaunchDeepLinkIfNeeded()
            selectDefaultYearIfNeeded()
        }
        .onChange(of: years.map(\.lunarYearNumber)) {
            selectDefaultYearIfNeeded()
        }
        .onOpenURL { url in
            open(url)
        }
    }

    private var emptyStateDescription: String {
        if years.isEmpty {
            return "正在加载 SwiftData 日历数据。"
        }

        return "请选择一个农历年。"
    }

    private func selectDefaultYearIfNeeded() {
        let yearNumbers = years.map(\.lunarYearNumber)
        guard !yearNumbers.isEmpty else {
            ChineseCalendarLog.ui.debug("CalendarHomeView is waiting for SwiftData years")
            return
        }

        if let selectedYearNumber = router.selectDefaultYearIfNeeded(
            availableYearNumbers: yearNumbers,
            preferredYearNumber: ChineseLunarCalendar.yearNumber()
        ) {
            ChineseCalendarLog.ui.info("Selected default lunar year \(selectedYearNumber)")
        }
    }

    private func openColdLaunchDeepLinkIfNeeded() {
        guard !didOpenColdLaunchDeepLink else {
            return
        }

        didOpenColdLaunchDeepLink = true
        router.openColdLaunchDeepLink(CalendarDeepLinkParser.deepLink(from: ProcessInfo.processInfo.arguments))
    }

    private func open(_ url: URL) {
        guard let deepLink = CalendarDeepLinkParser.deepLink(from: url) else {
            return
        }

        router.openDeepLink(deepLink)
    }
}

#Preview {
    CalendarHomeView()
}
