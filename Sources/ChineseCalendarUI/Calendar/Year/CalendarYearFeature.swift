import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import NavigationCore
import Observation
import SwiftData

/// 一个日历页面拥有的日期选择、年份过渡和本次年份选择器资源。
@MainActor
@Observable
final class CalendarYearFeature {
    let selection: CalendarSelection
    let today: CalendarToday
    let yearTransitionContext = LunarYearTransitionContext()
    private(set) var pendingYearTransition: LunarYearTransitionRequest?
    private(set) var yearPickerSession: CalendarYearPickerSession?
    private(set) var modelContext: ModelContext?

    @ObservationIgnored private var yearPickerHandle: NavigationPresentationHandle?
    @ObservationIgnored private weak var storeCoordinator: ChineseCalendarStoreCoordinator?
    @ObservationIgnored private var storeObservation: Task<Void, Never>?
    private var storeIdentity: String?
    private var storeGeneration = 0

    init(selection: CalendarSelection = CalendarSelection(), today: CalendarToday = CalendarToday()) {
        self.selection = selection
        self.today = today
    }

    isolated deinit {
        storeObservation?.cancel()
    }

    func connect(modelContext: ModelContext, storeCoordinator: ChineseCalendarStoreCoordinator?) {
        synchronizeStoreIdentity()
        if let storeCoordinator {
            guard case let .ready(container, _, _) = storeCoordinator.state,
                  modelContext.container === container
            else { return }
        }
        if let currentContext = self.modelContext, currentContext !== modelContext {
            invalidateStoreResources()
        }
        self.modelContext = modelContext
        guard self.storeCoordinator !== storeCoordinator else { return }
        storeObservation?.cancel()
        self.storeCoordinator = storeCoordinator
        storeIdentity = storeCoordinator?.navigationStoreIdentity
        guard let storeCoordinator else { return }

        // 来源 View 被数据 identity 替换后，呈现配置仍保留本 feature；订阅不能随来源 View 消失而停止。
        storeObservation = Task { [weak self] in
            for await identity in Observations({ storeCoordinator.navigationStoreIdentity }) {
                guard !Task.isCancelled, let self else { return }
                storeIdentityDidChange(identity)
            }
        }
    }

    func presentYearPicker(
        presentation: CalendarPresentationContext,
        configuration: (CalendarYearPickerSession) -> some NavigationHostConfiguration<
            CalendarTab,
            CalendarDestination,
            CalendarAlert
        >
    ) {
        guard let session = beginYearPicker() else { return }
        let submission = presentation.present(
            .sheet(.yearPicker),
            configuration: configuration(session),
            onFinish: { [weak self, weak session] in
                guard let session else { return }
                self?.finishYearPicker(session: session)
            }
        )
        if submission.result.isAccepted {
            if yearPickerSession === session {
                yearPickerHandle = submission.handle
            } else {
                submission.handle?.dismiss()
            }
        } else {
            finishYearPicker(session: session)
        }
    }

    func beginYearPicker() -> CalendarYearPickerSession? {
        synchronizeStoreIdentity()
        guard yearPickerSession == nil, let modelContext else { return nil }
        let session = CalendarYearPickerSession(
            selection: selection, modelContext: modelContext, storeGeneration: storeGeneration
        )
        yearPickerSession = session
        return session
    }

    func finishYearPicker(session: CalendarYearPickerSession) {
        session.invalidate()
        guard yearPickerSession === session else { return }
        yearPickerHandle = nil
        yearPickerSession = nil
    }

    /// 模态已接受关闭后调用；结果只能消费一次，且不得跨数据容器提交。
    func selectYear(_ yearNumber: Int, session: CalendarYearPickerSession) {
        synchronizeStoreIdentity()
        guard yearPickerSession === session,
              session.storeGeneration == storeGeneration,
              session.modelContext === modelContext,
              session.consumeResult()
        else { return }
        prepareYearSelection(yearNumber)
    }

    func selectMonth(_ destinationMonth: ChineseLunarMonth?, from sourceMonth: ChineseLunarMonth) {
        synchronizeStoreIdentity()
        guard modelContext != nil, let destinationMonth,
              destinationMonth.lunarMonthIndex != sourceMonth.lunarMonthIndex,
              let sourceYearNumber = sourceMonth.chineseLunarYear?.lunarYearNumber,
              let destinationYearNumber = destinationMonth.chineseLunarYear?.lunarYearNumber
        else { return }
        let crossesYear = destinationYearNumber != sourceYearNumber
        updateTransitionDirection(from: sourceYearNumber, to: destinationYearNumber)
        ChineseCalendarPerformanceSignposts.shared.beginMonthSwitch(
            from: sourceMonth.lunarMonthIndex, to: destinationMonth.lunarMonthIndex, crossesYear: crossesYear
        )
        pendingYearTransition = nil
        selectDay(inMonth: destinationMonth.lunarMonthIndex)
    }

    func selectToday() {
        synchronizeStoreIdentity()
        guard let resolver else { return }
        pendingYearTransition = nil
        today.refresh()
        do {
            let destinationDayIndex = try resolver.todayDayIndex(julianDayNumber: today.julianDayNumber)
            let destinationYearNumber = try resolver.yearNumber(forDayIndex: destinationDayIndex)
            let sourceYearNumber = try resolver.yearNumber(forDayIndex: selection.selectedDayIndex)
            if let destinationYearNumber, let sourceYearNumber {
                updateTransitionDirection(from: sourceYearNumber, to: destinationYearNumber)
            }
            selection.select(dayIndex: destinationDayIndex)
        } catch {
            ChineseCalendarLog.ui.error("无法选择今天：\(error.localizedDescription)")
            selection.select(dayIndex: nil)
        }
    }

    func completeYearTransitionPreparation(_ sourceMonthIndex: Int) {
        synchronizeStoreIdentity()
        guard let resolver, let request = pendingYearTransition,
              request.sourceMonthIndex == sourceMonthIndex,
              request.sourceYearNumber == (try? resolver.yearNumber(forDayIndex: selection.selectedDayIndex))
        else { return }
        pendingYearTransition = nil
        if let destinationMonthIndex = request.destinationMonthIndex {
            selectDay(inMonth: destinationMonthIndex)
        } else {
            selection.select(dayIndex: nil)
        }
    }

    private func prepareYearSelection(_ yearNumber: Int) {
        guard let resolver else { return }
        do {
            guard let sourceYearNumber = try resolver.yearNumber(forDayIndex: selection.selectedDayIndex),
                  let direction = LunarYearTransitionDirection(from: sourceYearNumber, to: yearNumber)
            else { return }
            yearTransitionContext.direction = direction
            let destinationMonthIndex = try resolver.boundaryMonthIndex(
                inYear: yearNumber, direction: direction, isSource: false
            )
            guard let sourceMonthIndex = try resolver.boundaryMonthIndex(
                inYear: sourceYearNumber, direction: direction, isSource: true
            ) else {
                pendingYearTransition = nil
                try selection.select(dayIndex: resolver.selectedDayIndex(
                    inBoundaryMonthOf: yearNumber, direction: direction,
                    todayJulianDayNumber: today.julianDayNumber
                ))
                return
            }
            pendingYearTransition = LunarYearTransitionRequest(
                sourceYearNumber: sourceYearNumber, sourceMonthIndex: sourceMonthIndex,
                destinationYearNumber: yearNumber, destinationMonthIndex: destinationMonthIndex
            )
        } catch {
            ChineseCalendarLog.ui.error("无法准备农历年份切换：\(error.localizedDescription)")
            pendingYearTransition = nil
            selection.select(dayIndex: nil)
        }
    }

    private func updateTransitionDirection(from source: Int, to destination: Int) {
        if let direction = LunarYearTransitionDirection(from: source, to: destination) {
            yearTransitionContext.direction = direction
        }
    }

    private func selectDay(inMonth monthIndex: Int) {
        guard let resolver else { return }
        do {
            try selection.select(dayIndex: resolver.selectedDayIndex(
                for: .month(index: monthIndex), todayJulianDayNumber: today.julianDayNumber
            ))
        } catch {
            ChineseCalendarLog.ui.error("无法选择目标月份的日期：\(error.localizedDescription)")
            selection.select(dayIndex: nil)
        }
    }

    private var resolver: CalendarSelectionResolver? {
        modelContext.map(CalendarSelectionResolver.init(modelContext:))
    }

    private func synchronizeStoreIdentity() {
        guard let storeCoordinator else { return }
        storeIdentityDidChange(storeCoordinator.navigationStoreIdentity)
    }

    private func storeIdentityDidChange(_ identity: String?) {
        guard storeIdentity != identity else { return }
        storeIdentity = identity
        invalidateStoreResources()
        modelContext = nil
    }

    private func invalidateStoreResources() {
        storeGeneration += 1
        pendingYearTransition = nil
        yearPickerSession?.invalidate()
        yearPickerHandle?.dismiss()
    }
}
