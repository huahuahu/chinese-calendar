import ChineseCalendarCore
import ChineseCalendarLocalization
import NavigationCore
import SFSafeSymbols
import SwiftUI

/// 以当前层的独立栈组织日历、历史和设置；根层与任意模态层均可复用。
struct CalendarHomeTabView: View {
    @Environment(CalendarPresentationContext.self) private var presentation
    @Environment(ChineseCalendarStoreCoordinator.self) private var storeCoordinator: ChineseCalendarStoreCoordinator?

    var body: some View {
        @Bindable var presentation = presentation

        TabView(selection: $presentation.selectedStack) {
            Tab(value: NavigationStackID<CalendarTab>.scope(.years)) {
                NavigationScopeView(
                    stack: .scope(.years),
                    presentation: presentation
                )
            } label: {
                Label(CalendarTab.years.title, systemSymbol: CalendarTab.years.systemSymbol)
            }

            Tab(value: NavigationStackID<CalendarTab>.scope(.history)) {
                CalendarHistoryHomeView(stack: .scope(.history))
            } label: {
                Label(CalendarTab.history.title, systemSymbol: CalendarTab.history.systemSymbol)
            }

            Tab(value: NavigationStackID<CalendarTab>.scope(.settings)) {
                NavigationScopeView(
                    stack: .scope(.settings),
                    presentation: presentation
                )
            } label: {
                Label(CalendarTab.settings.title, systemSymbol: CalendarTab.settings.systemSymbol)
            }
        }
        .calendarTabViewBottomAccessory(isEnabled: isDownloadAccessoryPresented) {
            downloadAccessory
        }
        .background(.calendarSystemBackground)
    }

    private var isDownloadAccessoryPresented: Bool {
        guard let storeCoordinator, case let .ready(_, contentLevel, _) = storeCoordinator.state else { return false }
        return storeCoordinator.fullStoreDownloadProgress != nil ||
            storeCoordinator.canDownloadFullStore(contentLevel: contentLevel)
    }

    @ViewBuilder
    private var downloadAccessory: some View {
        if let storeCoordinator, case let .ready(_, contentLevel, _) = storeCoordinator.state {
            if let progress = storeCoordinator.fullStoreDownloadProgress {
                CalendarDownloadProgressAccessory(progress: progress)
            } else if storeCoordinator.canDownloadFullStore(contentLevel: contentLevel) {
                FullStoreDownloadBanner(action: startFullStoreDownload)
            }
        }
    }

    private func startFullStoreDownload() {
        storeCoordinator?.startFullStoreDownload()
    }
}
