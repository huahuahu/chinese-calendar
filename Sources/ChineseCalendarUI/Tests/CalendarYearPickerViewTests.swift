@testable import ChineseCalendarUI
import Testing

@Test func yearPickerInitialScrollTargetFindsSelectedYear() {
    let target = CalendarYearPickerView.initialScrollTarget(
        selectedYearNumber: 2026,
        availableYearNumbers: [2024, 2025, 2026, 2027]
    )

    #expect(target == 2026)
}

@Test func yearPickerInitialScrollTargetIsNilWithoutSelection() {
    let target = CalendarYearPickerView.initialScrollTarget(
        selectedYearNumber: nil,
        availableYearNumbers: [2024, 2025, 2026]
    )

    #expect(target == nil)
}

@Test func yearPickerInitialScrollTargetIsNilWhenSelectionIsUnavailable() {
    let target = CalendarYearPickerView.initialScrollTarget(
        selectedYearNumber: 1900,
        availableYearNumbers: [2024, 2025, 2026]
    )

    #expect(target == nil)
}
