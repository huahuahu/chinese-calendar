import ChineseCalendarLocalization
import SFSafeSymbols
import SwiftUI

/// 供导航容器使用，将 CalendarDestination 分发到对应页面。
struct CalendarDestinationView: View {
    let destination: CalendarDestination
    @Environment(CalendarPresentationContext.self) private var presentation
    @Environment(ChineseCalendarStoreCoordinator.self) private var storeCoordinator: ChineseCalendarStoreCoordinator?

    var body: some View {
        Group {
            switch destination {
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
            case let .emperorList(dynastyID):
                EmperorListView(dynastyID: dynastyID)
            case let .reignEraList(dynastyID):
                ReignEraListView(dynastyID: dynastyID)
            case let .dynastySpan(orthodoxPeriodID):
                DynastySpanDetailView(orthodoxPeriodID: orthodoxPeriodID)
            case let .reignEra(reignEraID):
                ReignEraDetailView(reignEraID: reignEraID)
            case let .emperor(emperorID):
                EmperorDetailView(emperorID: emperorID)
            case let .yearPicker(sessionID):
                CalendarYearPickerDestinationView(sessionID: sessionID)
            case .downloadDetails:
                if let progress = storeCoordinator?.fullStoreDownloadProgress {
                    FullStoreDownloadDetailView(progress: progress)
                }
            #if DEBUG
                case let .debugNavigation(id):
                    CalendarDebugNavigationView(id: id)
                case let .downloadPreview(sessionID):
                    FullStoreDownloadPreviewDestinationView(sessionID: sessionID)
                case let .downloadPreviewDetails(sessionID):
                    FullStoreDownloadPreviewDetailView(sessionID: sessionID)
            #endif
            }
        }
        // 数据替换只重建页面内容，所在栈和呈现宿主继续完成导航事务。
        .id(storeCoordinator?.navigationStoreIdentity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.calendarSystemBackground)
        .toolbar {
            if presentation.isPresented, destination.usesPresentationNavigationStack {
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
}
