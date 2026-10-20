import ChineseCalendarLocalization
#if DEBUG
    import NavigationCore
    import SFSafeSymbols
    import SwiftUI

    /// 使用真实 TabView 附件，固定各下载阶段以便检查布局和无障碍。
    struct FullStoreDownloadPreview: View {
        @Environment(CalendarPresentationContext.self) private var presentation
        @Bindable var state: FullStoreDownloadPreviewState

        var body: some View {
            @Bindable var presentation = presentation
            TabView(selection: $presentation.selectedStack) {
                Tab(value: NavigationStackID<CalendarTab>.scope(.years)) {
                    NavigationScopeView(
                        stack: .scope(.years), presentation: presentation
                    )
                } label: {
                    Label(CalendarStringKey.Settings.Debug.DownloadPreview.scenariosTab, systemSymbol: .arrowDownCircle)
                }

                Tab(value: NavigationStackID<CalendarTab>.scope(.history)) {
                    NavigationScopeView(
                        stack: .scope(.history), presentation: presentation
                    )
                } label: {
                    Label(CalendarStringKey.Settings.Debug.DownloadPreview.switchTab, systemSymbol: .checkmarkCircle)
                }
            }
            .tabBarMinimizeBehavior(.onScrollDown)
            .calendarTabViewBottomAccessory(isEnabled: true) {
                FullStoreDownloadBottomProgressView(progress: state.stage.progress) {
                    presentation.present(.downloadPreviewDetails(sessionID: state.id))
                }
            }
            .dynamicTypeSize(state.textSize)
        }
    }

    #Preview("底部下载进度") {
        FullStoreDownloadPreviewHost()
    }
#endif
