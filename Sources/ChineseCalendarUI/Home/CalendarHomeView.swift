import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import Foundation
import SwiftData
import SwiftUI

/// 显示在应用根视图中，负责组织日历主页、导航与平台布局。
public struct CalendarHomeView<BottomStatusBar: View>: View {
    @Query(sort: \ChineseLunarYear.lunarYearNumber) private var years: [ChineseLunarYear]
    @State private var coordinator = CalendarHomeCoordinator()
    @State private var didOpenColdLaunchDeepLink = false
    private let settingsCoordinator: ChineseCalendarStoreCoordinator?
    private let bottomStatusBarIsPresented: Bool
    private let bottomStatusBar: () -> BottomStatusBar

    public init(
        settingsCoordinator: ChineseCalendarStoreCoordinator? = nil,
        bottomStatusBarIsPresented: Bool = false,
        @ViewBuilder bottomStatusBar: @escaping () -> BottomStatusBar
    ) {
        self.settingsCoordinator = settingsCoordinator
        self.bottomStatusBarIsPresented = bottomStatusBarIsPresented
        self.bottomStatusBar = bottomStatusBar
    }

    public var body: some View {
        @Bindable var router = coordinator.router

        Group {
            #if os(iOS)
                CalendarHomeTabView(
                    coordinator: coordinator,
                    emptyStateDescription: emptyStateDescription,
                    settingsCoordinator: settingsCoordinator,
                    bottomStatusBar: bottomStatusBar
                )
            #else
                CalendarHomeSplitView(
                    coordinator: coordinator,
                    years: years,
                    emptyStateDescription: emptyStateDescription
                )
            #endif
        }
        .environment(router)
        .environment(\.calendarBottomStatusBarIsPresented, bottomStatusBarIsPresented)
        .sheet(item: $router.sheet, onDismiss: coordinator.applyDeferredDeepLinkIfReady) { node in
            CalendarPresentationNodeView(node: node) {
                router.dismissSheet()
            }
        }
        .calendarFullScreenCover(item: $router.fullScreen, onDismiss: coordinator.applyDeferredDeepLinkIfReady) { node in
            CalendarPresentationNodeView(node: node) {
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

        if let selectedYearNumber = coordinator.selectDefaultYearIfNeeded(
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
        coordinator.openColdLaunchDeepLink(CalendarDeepLinkParser.deepLink(from: ProcessInfo.processInfo.arguments))
    }

    private func open(_ url: URL) {
        guard let deepLink = CalendarDeepLinkParser.deepLink(from: url) else {
            return
        }

        coordinator.openDeepLink(deepLink)
    }
}

#Preview {
    CalendarHomeView()
}

public extension CalendarHomeView where BottomStatusBar == EmptyView {
    init(settingsCoordinator: ChineseCalendarStoreCoordinator? = nil) {
        self.settingsCoordinator = settingsCoordinator
        bottomStatusBarIsPresented = false
        bottomStatusBar = { EmptyView() }
    }

    @available(*, deprecated, message: "CalendarHomeView now selects the current lunar year automatically.")
    init(selectedDate _: ChineseCalendarDate?) {
        self.init()
    }
}
