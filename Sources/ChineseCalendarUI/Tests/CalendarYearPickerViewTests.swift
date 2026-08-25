import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import CoreGraphics
import Testing

@Test(
    "天文学纪年映射到没有 0 世纪的公元前与公元世纪",
    arguments: [
        (-220, -3),
        (-199, -2),
        (-100, -2),
        (-99, -1),
        (0, -1),
        (1, 1),
        (100, 1),
        (101, 2),
        (2026, 21)
    ]
)
func yearPickerMapsYearsToSignedCenturies(lunarYearNumber: Int, expectedCentury: Int) {
    #expect(CalendarYearSection.signedCentury(lunarYearNumber: lunarYearNumber) == expectedCentury)
}

@Test func yearPickerGroupsYearsIntoChronologicalIndexedSections() {
    let yearNumbers = [-220, -199, 0, 1, 100, 101, 2026]
    let years = yearNumbers.map {
        ChineseLunarYear(lunarYearNumber: $0, yearStemIndex: 0, yearBranchIndex: 0)
    }

    let sections = CalendarYearSection.sections(for: years)

    #expect(sections.map(\.id) == [-3, -2, -1, 1, 2, 21])
    #expect(sections.map(\.title) == [
        "公元前 3 世纪",
        "公元前 2 世纪",
        "公元前 1 世纪",
        "公元 1 世纪",
        "公元 2 世纪",
        "公元 21 世纪"
    ])
    #expect(sections.map(\.indexTitle) == ["前3", "前2", "前1", "1", "2", "21"])
    #expect(sections.flatMap(\.years).map(\.lunarYearNumber) == yearNumbers)
}

@Test func yearPickerBuildsDirectScrollTargetsForSectionHeadersAndYears() {
    let years = [100, 101].map {
        ChineseLunarYear(lunarYearNumber: $0, yearStemIndex: 0, yearBranchIndex: 0)
    }

    let items = CalendarYearPickerItem.items(for: CalendarYearSection.sections(for: years))

    #expect(items.map(\.id) == [
        .section(1),
        .year(100),
        .section(2),
        .year(101)
    ])
    #expect(CalendarYearPickerItem.ID.year(2026).sectionID == 21)
}

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

@Test(
    "世纪索引将触点限制并映射到对应分区",
    arguments: [
        (-10, 0),
        (0, 0),
        (24, 0),
        (25, 1),
        (74, 2),
        (75, 3),
        (100, 3),
        (110, 3)
    ]
)
func yearPickerSectionIndexMapsVerticalOffsets(verticalOffset: Double, expectedIndex: Int) {
    let index = CalendarYearSectionIndex.sectionIndex(
        at: CGFloat(verticalOffset),
        indexHeight: 100,
        sectionCount: 4
    )

    #expect(index == expectedIndex)
}

@Test func yearPickerSectionIndexRejectsEmptyGeometryOrSections() {
    #expect(CalendarYearSectionIndex.sectionIndex(at: 0, indexHeight: 0, sectionCount: 4) == nil)
    #expect(CalendarYearSectionIndex.sectionIndex(at: 0, indexHeight: 100, sectionCount: 0) == nil)
}
