import ChineseCalendarCore
import ChineseCalendarPersistence
import Foundation
import NavigationCore
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
        @Bindable var navigation = coordinator.router.navigation

        Group {
            #if os(iOS)
                CalendarHomeTabView(
                    coordinator: coordinator,
                    settingsCoordinator: settingsCoordinator,
                    bottomStatusBarIsPresented: bottomStatusBarIsPresented,
                    bottomStatusBar: bottomStatusBar
                )
            #else
                CalendarHomeSplitView(
                    coordinator: coordinator,
                    years: years
                )
            #endif
        }
        .environment(coordinator.router)
        .sheet(item: $navigation.sheet, onDismiss: applyDeferredNavigationRequestIfReady) { node in
            CalendarPresentationNodeView(node: node)
        }
        .navigationFullScreenCover(
            item: $navigation.fullScreen,
            onDismiss: applyDeferredNavigationRequestIfReady
        ) { node in
            CalendarPresentationNodeView(node: node)
        }
        .task {
            openColdLaunchDeepLinkIfNeeded()
        }
        .onOpenURL { url in
            open(url)
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

    private func applyDeferredNavigationRequestIfReady() {
        _ = coordinator.router.navigation.applyDeferredRequestIfReady()
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
