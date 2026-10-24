import ChineseCalendarCore
import ChineseCalendarLogging
import ChineseCalendarPersistence
import NavigationCore
import Observation
import SwiftData
import SwiftUI

/// 一个日历页面拥有的日期选择、年份过渡和本次年份选择器资源。
@MainActor
@Observable
final class CalendarYearFeature {
    let selection: CalendarSelection
    let today: CalendarToday
    let yearTransitionContext = LunarYearTransitionContext()
    private(set) var pendingYearTransition: LunarYearTransitionRequest?
    private(set) var yearPickerID: UUID?
    private var acceptsYearPickerResult = false
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

        // 数据库更换可能重建发起页，但选择器的 Binding 仍持有本 feature。
        // 因此由 feature 持续观察数据库变化，避免订阅随发起页销毁而停止。
        storeObservation = Task { [weak self] in
            for await identity in Observations({ storeCoordinator.navigationStoreIdentity }) {
                guard !Task.isCancelled, let self else { return }
                storeIdentityDidChange(identity)
            }
        }
    }

    func presentYearPicker(presentation: CalendarPresentationContext) {
        guard let destination = beginYearPicker(), let id = yearPickerID else { return }
        let submission = presentation.present(.sheet(destination), onDismiss: { [weak self] in
            self?.finishYearPicker(id: id)
        })
        if submission.result.isAccepted {
            yearPickerHandle = submission.handle
        } else {
            finishYearPicker(id: id)
        }
    }

    /// 创建时固定身份和数据上下文；Binding 只把结果交回这个发起页。
    func beginYearPicker() -> CalendarDestination? {
        synchronizeStoreIdentity()
        guard yearPickerID == nil, let modelContext else { return nil }
        let id = UUID()
        let generation = storeGeneration
        yearPickerID = id
        acceptsYearPickerResult = true
        let binding = Binding<Int?>(
            get: { try? CalendarSelectionResolver(modelContext: modelContext)
                .yearNumber(forDayIndex: self.selection.selectedDayIndex)
            },
            set: { yearNumber in
                self.synchronizeStoreIdentity()
                guard let yearNumber, self.yearPickerID == id, self.acceptsYearPickerResult,
                      self.storeGeneration == generation, self.modelContext === modelContext else { return }
                self.acceptsYearPickerResult = false
                self.prepareYearSelection(yearNumber)
            }
        )
        return .yearPicker(id: id, selection: binding, modelContext: modelContext)
    }

    func finishYearPicker(id: UUID) {
        guard yearPickerID == id else { return }
        acceptsYearPickerResult = false
        yearPickerHandle = nil
        yearPickerID = nil
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
        acceptsYearPickerResult = false
        yearPickerHandle?.dismiss()
        if let id = yearPickerID { finishYearPicker(id: id) }
    }
}
