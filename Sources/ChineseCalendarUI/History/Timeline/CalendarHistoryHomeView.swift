import ChineseCalendarLocalization
import ChineseCalendarPersistence
import NavigationCore
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 前两栏管理历史选择，最后一栏复用当前导航层的唯一详情栈。
struct CalendarHistoryHomeView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sidebarMinimumWidth: CGFloat = 280
        static let sidebarIdealWidth: CGFloat = 320
        static let sidebarMaximumWidth: CGFloat = 400
        static let contentMinimumWidth: CGFloat = 220
        static let contentIdealWidth: CGFloat = 260
        static let contentMaximumWidth: CGFloat = 340
    }

    var stack: NavigationStackID<CalendarTab> = .primary
    @Environment(CalendarHomeCoordinator.self) private var coordinator
    @Environment(CalendarPresentationContext.self) private var presentation
    @Environment(\.modelContext) private var modelContext
    @Query private var periods: [OrthodoxPeriod]

    init(stack: NavigationStackID<CalendarTab> = .primary) {
        self.stack = stack
        let traditionID = HistoryConfiguration.defaultOrthodoxTraditionID
        _periods = Query(
            filter: #Predicate<OrthodoxPeriod> { $0.tradition?.id == traditionID },
            sort: \OrthodoxPeriod.sequenceIndex
        )
    }

    private var navigation: CalendarNavigationContext {
        presentation.context(for: stack)
    }

    private var state: CalendarHistoryState {
        coordinator.historyState(for: navigation)
    }

    var body: some View {
        @Bindable var state = state

        NavigationSplitView(
            columnVisibility: $state.columnVisibility,
            preferredCompactColumn: $state.preferredCompactColumn
        ) {
            CalendarHistorySidebarView(periods: periods, selection: $state.orthodoxPeriodID)
                .navigationSplitViewColumnWidth(
                    min: Constants.sidebarMinimumWidth, ideal: Constants.sidebarIdealWidth,
                    max: Constants.sidebarMaximumWidth
                )
                .toolbar { closeToolbar }
        } content: {
            if let periodID = state.orthodoxPeriodID {
                CalendarHistoryContentView(orthodoxPeriodID: periodID, selection: $state.section)
                    .navigationSplitViewColumnWidth(
                        min: Constants.contentMinimumWidth, ideal: Constants.contentIdealWidth,
                        max: Constants.contentMaximumWidth
                    )
                    .toolbar { closeToolbar }
            } else {
                ContentUnavailableView {
                    Label(CalendarStringKey.History.Split.chooseDynastyTitle, systemSymbol: .buildingColumns)
                } description: {
                    Text(CalendarStringKey.History.Split.chooseDynastyMessage)
                }
                .toolbar { closeToolbar }
            }
        } detail: {
            NavigationScopeView(stack: stack, presentation: presentation)
        }
        .navigationSplitViewStyle(.balanced)
        .environment(presentation.scoped(to: stack))
        .onChange(of: navigation.rootDestination, initial: true) {
            synchronizeSelection()
        }
    }

    @ToolbarContentBuilder
    private var closeToolbar: some ToolbarContent {
        if presentation.isPresented {
            ToolbarItem(placement: .cancellationAction) {
                Button(CalendarStringKey.Common.Action.close) { presentation.dismiss() }
            }
        }
    }

    /// 外部请求实际换根之后，才解析皇帝所属时期；不在确认或关闭流程中预写选择。
    private func synchronizeSelection() {
        state.synchronizeRoot()
        guard case let .emperor(emperorID) = navigation.rootDestination else { return }
        var descriptor = FetchDescriptor<Emperor>(predicate: #Predicate { $0.id == emperorID })
        descriptor.fetchLimit = 1
        guard let emperor = try? modelContext.fetch(descriptor).first,
              let period = periods.first(where: { $0.dynasty?.id == emperor.dynasty.id })
        else { return }
        state.resolveEmperorRoot(emperorID: emperorID, orthodoxPeriodID: period.id)
    }
}

#Preview("历史三栏", traits: .sampleData) {
    CalendarHistoryHomeView(stack: .scope(.history))
}

#Preview("空时间线", traits: .emptySampleData) {
    CalendarHistoryHomeView(stack: .scope(.history))
}
