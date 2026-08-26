import SwiftUI

/// 显示在年份滚动视图右侧的轻量世纪索引。
struct CalendarYearSectionIndex: View {
    let width: CGFloat
    let sections: [CalendarYearSection]
    let currentSectionID: Int?
    let selectSection: (CalendarYearSection) -> Void

    @ScaledMetric(relativeTo: .caption2) private var rowHeight: CGFloat = 13
    @State private var activeSectionID: Int?

    var body: some View {
        GeometryReader { geometry in
            let indexHeight = min(geometry.size.height, CGFloat(sections.count) * rowHeight)

            VStack(spacing: 0) {
                ForEach(sections) { section in
                    Text(section.indexTitle)
                        .font(.caption2)
                        .fontWeight(section.id == currentSectionID ? .bold : .regular)
                        .foregroundStyle(section.id == activeSectionID ? Color.white : Color.accentColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            section.id == activeSectionID ? Color.accentColor : Color.clear,
                            in: .capsule
                        )
                }
            }
            .frame(width: width, height: indexHeight)
            .contentShape(Rectangle())
            .gesture(sectionSelectionGesture(indexHeight: indexHeight))
            .position(x: width / 2, y: geometry.size.height / 2)
        }
        .frame(width: width)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("世纪索引")
        .accessibilityValue(currentSectionTitle ?? "未选择世纪")
        .accessibilityAdjustableAction(adjustSelection)
    }

    static func sectionIndex(
        at verticalOffset: CGFloat,
        indexHeight: CGFloat,
        sectionCount: Int
    ) -> Int? {
        guard indexHeight > 0, sectionCount > 0 else {
            return nil
        }

        let boundedOffset = min(max(verticalOffset, 0), indexHeight.nextDown)
        return min(Int(boundedOffset / indexHeight * CGFloat(sectionCount)), sectionCount - 1)
    }

    private var currentSectionTitle: String? {
        sections.first { $0.id == currentSectionID }?.title
    }

    private func sectionSelectionGesture(indexHeight: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard let index = Self.sectionIndex(
                    at: value.location.y,
                    indexHeight: indexHeight,
                    sectionCount: sections.count
                ) else {
                    return
                }

                let section = sections[index]
                guard activeSectionID != section.id else {
                    return
                }

                activeSectionID = section.id
                selectSection(section)
            }
            .onEnded { _ in
                activeSectionID = nil
            }
    }

    private func adjustSelection(_ direction: AccessibilityAdjustmentDirection) {
        guard !sections.isEmpty else {
            return
        }

        let currentIndex = sections.firstIndex { $0.id == currentSectionID } ?? 0
        let targetIndex: Int
        switch direction {
        case .increment:
            targetIndex = min(currentIndex + 1, sections.index(before: sections.endIndex))
        case .decrement:
            targetIndex = max(currentIndex - 1, sections.startIndex)
        @unknown default:
            return
        }

        selectSection(sections[targetIndex])
    }
}
