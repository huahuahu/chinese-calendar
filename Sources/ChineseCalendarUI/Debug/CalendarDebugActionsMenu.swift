#if DEBUG
    import ChineseCalendarLocalization
    import SFSafeSymbols
    import SwiftUI

    /// App 的调试动作目录；新增类别在这里组合，页面呈现仍交给 Router。
    struct CalendarDebugActionsMenu: View {
        @Environment(CalendarPresentationContext.self) private var presentation
        let storeCoordinator: ChineseCalendarStoreCoordinator
        @Environment(CalendarHomeCoordinator.self) private var coordinator

        @State private var downloadPreview = FullStoreDownloadPreviewFeature()

        var body: some View {
            Menu {
                Menu {
                    CalendarDebugNavigationActions()
                    CalendarDebugSplitEntries()
                } label: {
                    Label(CalendarStringKey.Debug.Navigation.title, systemSymbol: .arrowTriangleBranch)
                }

                Menu {
                    Button(CalendarStringKey.Settings.Debug.simulateDownload) {
                        storeCoordinator.startSimulatedFullStoreDownload()
                    }
                    .disabled(!storeCoordinator.canStartSimulatedFullStoreDownload)
                    Button(CalendarStringKey.Settings.Debug.downloadPreview) {
                        downloadPreview.present(from: presentation)
                    }
                } label: {
                    Label(CalendarStringKey.Debug.downloadActions, systemSymbol: .arrowDownCircle)
                }
            } label: {
                Label(CalendarStringKey.Debug.actions, systemSymbol: .ladybug)
            }
        }
    }
#endif
