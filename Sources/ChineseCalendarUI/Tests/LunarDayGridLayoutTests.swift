import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import SwiftUI
import Testing

@Test(arguments: [
    (0.0, 30, 1),
    (207.0, 30, 2),
    (208.0, 30, 3),
    (600.0, 1, 1),
    (600.0, 0, 0)
])
func dayGridColumnCountRespectsSpacingAndItemCount(width: Double, items: Int, expected: Int) {
    let layout = LunarDayGridLayout(spacing: 8)
    #expect(layout.columnCount(availableWidth: width, minimumWidth: 64, itemCount: items) == expected)
}

@MainActor
@Test func dayCellMinimumComesFromSingleLineContent() throws {
    let titleSize = try measuredSize(
        of: Text("初一").font(.headline).padding(.horizontal, 6),
        proposal: .unspecified
    )
    let ganZhiSize = try measuredSize(of: Text("甲子").font(.subheadline), proposal: .unspecified)
    let cellSize = try measuredSize(of: makeCell(), proposal: ProposedViewSize(width: 0, height: nil))

    #expect(abs(cellSize.width - (max(titleSize.width, ganZhiSize.width) + 20)) < 0.5)
}

@MainActor
@Test func longCivilDateDoesNotIncreaseCellMinimumWidth() throws {
    let proposal = ProposedViewSize(width: 0, height: nil)
    let shortDate = try measuredSize(of: makeCell(julianDayNumber: 2_461_043), proposal: proposal)
    let longDate = try measuredSize(of: makeCell(julianDayNumber: 2_461_042), proposal: proposal)

    #expect(shortDate.width == longDate.width)
    #expect(longDate.height > shortDate.height)
}

@MainActor
@Test func civilDateWrapsAtTheAssignedColumnWidth() throws {
    let minimum = try measuredSize(of: makeCell(), proposal: ProposedViewSize(width: 0, height: nil))
    let narrow = try measuredSize(of: makeCell(), proposal: ProposedViewSize(width: minimum.width, height: nil))
    let wide = try measuredSize(of: makeCell(), proposal: ProposedViewSize(width: 400, height: nil))

    #expect(narrow.width == minimum.width)
    #expect(wide.width == 400)
    #expect(narrow.height > wide.height)
}

@MainActor
@Test func dynamicTypeIncreasesMeasuredMinimumAndReducesColumns() throws {
    let proposal = ProposedViewSize(width: 0, height: nil)
    let regular = try measuredSize(of: makeCell(), proposal: proposal)
    let large = try measuredSize(
        of: makeCell().environment(\.dynamicTypeSize, .accessibility5),
        proposal: proposal
    )
    let layout = LunarDayGridLayout()

    #expect(large.width > regular.width)
    #expect(layout.columnCount(availableWidth: 329, minimumWidth: large.width, itemCount: 30)
        < layout.columnCount(availableWidth: 329, minimumWidth: regular.width, itemCount: 30))
}

@MainActor
@Test func plainButtonPreservesTheCellsMeasuredMinimum() throws {
    let cell = makeCell()
    let button = Button {} label: { cell }.buttonStyle(.plain)
    let proposal = ProposedViewSize(width: 0, height: nil)
    let cellSize = try measuredSize(of: cell, proposal: proposal)
    let buttonSize = try measuredSize(of: button, proposal: proposal)

    #expect(buttonSize.width == cellSize.width)
    #expect(buttonSize.height == cellSize.height)
}

@MainActor
@Test(arguments: [CGFloat(320), 393, 768], [DynamicTypeSize.large, .accessibility1, .accessibility5])
func dayGridFitsAvailableWidth(width: CGFloat, typeSize: DynamicTypeSize) throws {
    let grid = LunarDayGridLayout {
        ForEach(0 ..< 30) { index in
            Button {} label: { makeCell(julianDayNumber: 2_461_030 + index) }
                .buttonStyle(.plain)
        }
    }
    .environment(\.dynamicTypeSize, typeSize)
    let size = try measuredSize(of: grid, proposal: ProposedViewSize(width: width, height: nil))

    #expect(size.width == width)
    #expect(size.height > 0)
    #expect(size.height.isFinite)
}

@MainActor
@Test func dayGridUsesTheTallestCellInEachRow() throws {
    let grid = LunarDayGridLayout(spacing: 8) {
        Color.clear.frame(width: 64, height: 100)
        Color.clear.frame(width: 64, height: 150)
        Color.clear.frame(width: 64, height: 80)
    }
    let size = try measuredSize(of: grid, proposal: ProposedViewSize(width: 136, height: nil))

    #expect(size == CGSize(width: 136, height: 238))
}

@MainActor
@Test func dayGridCacheHandlesRepeatedAndDifferentWidthProposals() throws {
    let renderer = ImageRenderer(content: makeSizedGrid(cellSizes: [
        CGSize(width: 64, height: 100),
        CGSize(width: 64, height: 150),
        CGSize(width: 64, height: 80)
    ]))
    let cases: [(width: CGFloat?, expected: CGSize)] = [
        (136, CGSize(width: 136, height: 238)),
        (136, CGSize(width: 136, height: 238)),
        (208, CGSize(width: 208, height: 150)),
        (64, CGSize(width: 64, height: 346)),
        (136, CGSize(width: 136, height: 238)),
        (nil, CGSize(width: 208, height: 150)),
        (.infinity, CGSize(width: 208, height: 150)),
        (0, CGSize(width: 64, height: 346))
    ]

    for testCase in cases {
        let size = try measuredSize(
            using: renderer,
            proposal: ProposedViewSize(width: testCase.width, height: nil)
        )
        #expect(size == testCase.expected)
    }
}

@MainActor
@Test func dayGridCacheInvalidatesWhenContentChanges() throws {
    let renderer = ImageRenderer(content: makeSizedGrid(cellSizes: []))
    let cases: [(cells: [CGSize], height: CGFloat)] = [
        (Array(repeating: CGSize(width: 64, height: 100), count: 3), 208),
        (Array(repeating: CGSize(width: 80, height: 100), count: 3), 316),
        (Array(repeating: CGSize(width: 80, height: 140), count: 3), 436),
        ([CGSize(width: 80, height: 140)], 140),
        ([], 0),
        (Array(repeating: CGSize(width: 64, height: 100), count: 2), 100)
    ]

    for testCase in cases {
        renderer.content = makeSizedGrid(cellSizes: testCase.cells)
        let size = try measuredSize(using: renderer, proposal: ProposedViewSize(width: 136, height: nil))
        #expect(size == CGSize(width: testCase.cells.isEmpty ? 0 : 136, height: testCase.height))
    }
}

@MainActor
@Test func dayGridCacheInvalidatesWhenSpacingChanges() throws {
    let cells = Array(repeating: CGSize(width: 64, height: 100), count: 2)
    let renderer = ImageRenderer(content: makeSizedGrid(cellSizes: cells))
    let cases: [(spacing: CGFloat, height: CGFloat)] = [(8, 100), (16, 216), (8, 100)]

    for testCase in cases {
        renderer.content = makeSizedGrid(cellSizes: cells, spacing: testCase.spacing)
        let size = try measuredSize(using: renderer, proposal: ProposedViewSize(width: 136, height: nil))
        #expect(size == CGSize(width: 136, height: testCase.height))
    }
}

@MainActor
@Test func dayGridCacheUpdatesWhenDynamicTypeChanges() throws {
    let grid = LunarDayGridLayout {
        ForEach(0 ..< 6) { _ in
            makeCell()
        }
    }
    let renderer = ImageRenderer(content: grid.environment(\.dynamicTypeSize, .large))
    let proposal = ProposedViewSize(width: 320, height: nil)
    let regular = try measuredSize(using: renderer, proposal: proposal)

    renderer.content = grid.environment(\.dynamicTypeSize, .accessibility5)
    let enlarged = try measuredSize(using: renderer, proposal: proposal)
    let fresh = try measuredSize(of: grid.environment(\.dynamicTypeSize, .accessibility5), proposal: proposal)
    #expect(enlarged == fresh)
    #expect(enlarged.height > regular.height)

    renderer.content = grid.environment(\.dynamicTypeSize, .large)
    let restored = try measuredSize(using: renderer, proposal: proposal)
    #expect(restored == regular)
}

@MainActor
private func makeSizedGrid(cellSizes: [CGSize], spacing: CGFloat = 8) -> some View {
    LunarDayGridLayout(spacing: spacing) {
        ForEach(cellSizes.indices, id: \.self) { index in
            Color.clear.frame(width: cellSizes[index].width, height: cellSizes[index].height)
        }
    }
}

@MainActor
private func makeCell(julianDayNumber: Int = 2_461_042) -> some View {
    LunarDayGridCell(
        day: ChineseLunarDay(
            dayIndex: 1,
            lunarMonthIndex: 0,
            dayNumberInMonth: 1,
            dayStemIndex: 0,
            dayBranchIndex: 0,
            calendarDay: CalendarDay(dayIndex: 1, julianDayNumber: julianDayNumber)
        ),
        isSelected: false,
        isToday: false
    )
    .environment(\.locale, Locale(identifier: "zh_CN"))
}

@MainActor
private func measuredSize(of content: some View, proposal: ProposedViewSize) throws -> CGSize {
    let renderer = ImageRenderer(content: content)
    return try measuredSize(using: renderer, proposal: proposal)
}

@MainActor
private func measuredSize(
    using renderer: ImageRenderer<some View>,
    proposal: ProposedViewSize
) throws -> CGSize {
    renderer.proposedSize = proposal
    var measured: CGSize?
    renderer.render { size, _ in measured = size }
    return try #require(measured)
}
