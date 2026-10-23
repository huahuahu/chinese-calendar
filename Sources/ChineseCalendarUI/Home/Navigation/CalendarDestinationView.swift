import ChineseCalendarCore
import ChineseCalendarLocalization
import SFSafeSymbols
import SwiftUI

/// 供导航容器使用，将 CalendarDestination 分发到对应页面。
struct CalendarDestinationView<BottomStatusBar: View>: View {
    let destination: CalendarDestination
    let bottomStatusBarIsPresented: () -> Bool
    let bottomStatusBar: () -> BottomStatusBar
    var yearFeature: CalendarYearFeature?
    var yearPickerSession: CalendarYearPickerSession?
    #if DEBUG
        @Environment(FullStoreDownloadPreviewState
            .self) private var downloadPreviewState: FullStoreDownloadPreviewState?
    #endif
    @Environment(CalendarPresentationContext.self) private var presentation
    @Environment(CalendarNavigationContext.self) private var navigation: CalendarNavigationContext?
    @Environment(ChineseCalendarStoreCoordinator.self) private var storeCoordinator: ChineseCalendarStoreCoordinator?

    var body: some View {
        Group {
            switch destination {
            case .mainTabs:
                CalendarHomeTabView(
                    bottomStatusBarIsPresented: bottomStatusBarIsPresented(),
                    bottomStatusBar: bottomStatusBar
                )
            case .calendarHome:
                LunarYearDestinationView(landing: .year(number: ChineseLunarCalendar.yearNumber()))
            case .historyHome:
                CalendarHistoryHomeView()
            case .historyEmpty:
                CalendarHistoryEmptyDetailView()
            case let .historyDetail(orthodoxPeriodID, section):
                CalendarHistoryDetailView(orthodoxPeriodID: orthodoxPeriodID, section: section)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case let .historyEmperor(_, emperorID):
                EmperorDetailView(emperorID: emperorID)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case .settings:
                if let storeCoordinator {
                    CalendarSettingsView(coordinator: storeCoordinator, showsDoneButton: false)
                } else {
                    ContentUnavailableView {
                        Label(CalendarStringKey.Settings.Unavailable.title, systemSymbol: .gearshape)
                    } description: {
                        Text(CalendarStringKey.Settings.Unavailable.message)
                    }
                }
            case let .lunarYear(yearNumber, monthIndex, dayIndex):
                // 在导航边界选取地址中最具体的定位信息，页面只接收一种落点。
                let landing: LunarCalendarLanding = if let dayIndex {
                    .day(index: dayIndex)
                } else if let monthIndex {
                    .month(index: monthIndex)
                } else {
                    .year(number: yearNumber)
                }

                LunarYearDestinationView(landing: landing)
                    .id(destination)
            case let .dynasty(orthodoxPeriodID):
                DynastyDetailView(orthodoxPeriodID: orthodoxPeriodID)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case let .emperorList(dynastyID):
                EmperorListView(dynastyID: dynastyID)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case let .reignEraList(dynastyID):
                ReignEraListView(dynastyID: dynastyID)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case let .dynastySpan(orthodoxPeriodID):
                DynastySpanDetailView(orthodoxPeriodID: orthodoxPeriodID)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case let .reignEra(reignEraID):
                ReignEraDetailView(reignEraID: reignEraID)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case let .emperor(emperorID):
                EmperorDetailView(emperorID: emperorID)
                    .calendarStoreContent(state: storeCoordinator?.state)
            case .yearPicker:
                if let yearFeature, let yearPickerSession {
                    CalendarYearPickerDestinationView(feature: yearFeature, session: yearPickerSession)
                }
            case .downloadDetails:
                if let progress = storeCoordinator?.fullStoreDownloadProgress {
                    FullStoreDownloadDetailView(progress: progress)
                }
            #if DEBUG
                case let .debugNavigation(id):
                    CalendarDebugNavigationView(id: id)
                case let .debugSplit(layout):
                    CalendarDebugSplitView(layout: layout)
                case .debugSplitEmpty:
                    ContentUnavailableView {
                        Label(CalendarStringKey.Debug.Split.emptyTitle, systemSymbol: .listBullet)
                    } description: {
                        Text(CalendarStringKey.Debug.Split.emptyMessage)
                    }
                case let .debugSplitDetail(item, level):
                    CalendarDebugSplitDetailView(item: item, level: level)
                case .debugNavigationTabs:
                    CalendarDebugNavigationTabsView()
                case .downloadPreview:
                    if let state = downloadPreviewState { FullStoreDownloadPreview(state: state) }
                case .downloadPreviewScenarios:
                    if let state = downloadPreviewState {
                        FullStoreDownloadPreviewScenariosView(state: state)
                    }
                case .downloadPreviewSwitch:
                    Text(CalendarStringKey.Settings.Debug.DownloadPreview.switchMessage)
                        .padding()
                        .navigationTitle(CalendarStringKey.Settings.Debug.DownloadPreview.switchTab)
                case .downloadPreviewDetails:
                    if let state = downloadPreviewState { FullStoreDownloadPreviewDetailView(state: state) }
            #endif
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.calendarSystemBackground)
        .toolbar {
            if showsDismissButton {
                if destination.isDownloadDetail {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(
                            CalendarStringKey.Common.Action.close, systemSymbol: .xmark,
                            action: { presentation.dismiss() }
                        )
                    }
                } else {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(CalendarStringKey.Common.Action.close, action: { presentation.dismiss() })
                    }
                }
            }
        }
    }

    private var showsDismissButton: Bool {
        presentation.isPresented && !destination.providesNavigationContainer &&
            navigation?.path.isEmpty == true && navigation?.rootDestination == destination
    }
}
