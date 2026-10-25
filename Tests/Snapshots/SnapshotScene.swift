@testable import ChineseCalendarUI
import SwiftUI

/// 截图场景只定义页面内容和数据选择；设备、外观与字号由测试矩阵固定。
enum SnapshotScene: String, CaseIterable {
    case calendar = "calendar-modern"
    case beforeCommonEra = "calendar-before-common-era"
    case commonEra = "calendar-common-era"
    case civilEraBoundary = "calendar-civil-era-boundary"
    case postNinthMonth = "calendar-post-ninth-month"
    case emptyCalendar = "calendar-empty"
    case baseCalendar = "calendar-base-data"
    case yearPicker = "calendar-year-picker"
    case history = "history-timeline"
    case selectedHistory = "history-selected"
    case emptyHistory = "history-empty"
    case dynasty = "history-dynasty"
    case dynastySpan = "history-dynasty-span"
    case emperor = "history-emperor"
    case reignEra = "history-reign-era"
    case settingsStarting = "settings-starting"

    var slug: String {
        rawValue
    }

    var isEmptyData: Bool {
        self == .emptyCalendar || self == .emptyHistory
    }

    var scenario: PreviewCalendarScenario {
        switch self {
        case .beforeCommonEra: .beforeCommonEra
        case .commonEra: .commonEra
        case .civilEraBoundary: .civilEraBoundary
        case .postNinthMonth: .postNinthMonth
        default: .modern
        }
    }

    var tab: CalendarTab {
        switch self {
        case .history, .selectedHistory, .emptyHistory, .dynasty, .dynastySpan, .emperor, .reignEra:
            .history
        case .settingsStarting:
            .settings
        default:
            .years
        }
    }

    @MainActor @ViewBuilder
    var content: some View {
        switch self {
        case .calendar, .beforeCommonEra, .commonEra, .civilEraBoundary, .postNinthMonth:
            NavigationStack {
                CalendarPageView(selection: .day(index: scenario.selectedDayIndex))
            }
        case .emptyCalendar:
            NavigationStack {
                CalendarPageView(selection: nil)
            }
        case .baseCalendar:
            NavigationStack {
                CalendarPageView(selection: .month(index: PreviewBaseCalendarData.selectedMonthIndex))
            }
        case .yearPicker:
            NavigationStack {
                CalendarYearPickerView(selectedYearNumber: 2026) { _ in }
            }
        case .history, .selectedHistory, .emptyHistory:
            CalendarHistoryHomeView(stack: .scope(.history))
        case .dynasty:
            SampleNavigationPreview(tab: .history) {
                DynastyDetailView(orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID)
            }
        case .dynastySpan:
            NavigationStack {
                DynastySpanDetailView(orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID)
            }
        case .emperor:
            NavigationStack {
                EmperorDetailView(emperorID: HistoryPreviewData.emperorID)
            }
        case .reignEra:
            NavigationStack {
                ReignEraDetailView(reignEraID: HistoryPreviewData.reignEraID)
            }
        case .settingsStarting:
            SettingsContent()
        }
    }

    /// 设置使用宿主持有的独立 coordinator，不启动数据库安装或下载。
    private struct SettingsContent: View {
        @Environment(ChineseCalendarStoreCoordinator.self) private var coordinator: ChineseCalendarStoreCoordinator?

        var body: some View {
            if let coordinator {
                NavigationStack {
                    CalendarSettingsView(coordinator: coordinator, showsDoneButton: false)
                }
            }
        }
    }
}
