#if DEBUG
    import SwiftUI

    /// 将真实附件放进 TabView，并为点击详情提供独立、无下载任务的导航和存储状态。
    struct CalendarDownloadProgressAccessoryPreview: View {
        let progress: FullStoreDownloadProgress

        @State private var coordinator = CalendarHomeCoordinator()
        @State private var storeCoordinator: ChineseCalendarStoreCoordinator

        init(progress: FullStoreDownloadProgress) {
            self.progress = progress
            _storeCoordinator = State(initialValue: ChineseCalendarStoreCoordinator(previewDownloadProgress: progress))
        }

        var body: some View {
            TabView {
                Tab {
                    NavigationStack {
                        FullStoreDownloadDetailView(progress: progress)
                    }
                } label: {
                    Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
                }

                Tab {
                    NavigationStack {
                        FullStoreDownloadDetailView(progress: progress)
                    }
                } label: {
                    Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .calendarTabViewBottomAccessory(isEnabled: true) {
                CalendarDownloadProgressAccessory(progress: progress)
            }
            .calendarNavigationHost(coordinator: coordinator, storeCoordinator: storeCoordinator)
        }
    }
#endif
