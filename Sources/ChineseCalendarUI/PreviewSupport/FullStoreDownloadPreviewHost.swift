#if DEBUG
    import SwiftUI

    /// 独立 Preview 也使用实际的嵌套呈现入口。
    struct FullStoreDownloadPreviewHost: View {
        @State private var coordinator = CalendarHomeCoordinator()

        var body: some View {
            Color.clear
                .calendarNavigationHost(coordinator: coordinator)
                .task { coordinator.presentDownloadPreview() }
        }
    }
#endif
