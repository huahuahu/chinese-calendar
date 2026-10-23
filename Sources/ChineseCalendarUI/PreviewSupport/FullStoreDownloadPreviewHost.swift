#if DEBUG
    import SwiftUI

    /// 为独立 Preview 安装正式导航宿主，再通过 coordinator 打开下载演示模态，
    /// 使演示中的 Tab、详情 sheet 和关闭动作沿用 App 的导航流程。
    struct FullStoreDownloadPreviewHost: View {
        @State private var coordinator = CalendarHomeCoordinator()

        @State private var feature = FullStoreDownloadPreviewFeature()

        var body: some View {
            Color.clear
                .calendarNavigationHost(coordinator: coordinator)
                .task { feature.present(from: coordinator.router.navigation.rootPresentation, coordinator: coordinator)
                }
        }
    }
#endif
