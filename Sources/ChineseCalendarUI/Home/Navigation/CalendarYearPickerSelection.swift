@MainActor
final class CalendarYearPickerSelection {
    private var pendingYearNumber: Int?
    private let onSelect: (Int) -> Void

    init(onSelect: @escaping (Int) -> Void) {
        self.onSelect = onSelect
    }

    func prepare(_ yearNumber: Int) {
        pendingYearNumber = yearNumber
    }

    func commitIfNeeded() {
        guard let pendingYearNumber else {
            return
        }

        self.pendingYearNumber = nil
        onSelect(pendingYearNumber)
    }
}
