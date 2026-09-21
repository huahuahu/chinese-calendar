import SwiftUI

/// 以紧凑时间轴展示与朝代正统边界直接相关的少量事件。
struct DynastyBoundaryEventTimeline: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let listSpacing: CGFloat = 0
        static let eventRowSpacing: CGFloat = 12
        static let timeMinimumScaleFactor: CGFloat = 0.75
        static let timeWidth: CGFloat = 58
        static let timeMinimumHeight: CGFloat = 24
        static let timeBorderWidth: CGFloat = 1
        static let detailSpacing: CGFloat = 5
        static let rowVerticalPadding: CGFloat = 8
        static let railWidth: CGFloat = 1
        static let railVerticalInset: CGFloat = 20
        static let railHorizontalOffset: CGFloat = 29
    }

    let events: [HistoryBoundaryEvent]

    var body: some View {
        VStack(spacing: Constants.listSpacing) {
            ForEach(events) { event in
                eventRow(event)
            }
        }
        .background(alignment: .leading) {
            timelineRail
        }
    }

    private func eventRow(_ event: HistoryBoundaryEvent) -> some View {
        HStack(alignment: .top, spacing: Constants.eventRowSpacing) {
            timeBadge(event)
            eventDetails(event)
        }
        .padding(.vertical, Constants.rowVerticalPadding)
        .accessibilityElement(children: .combine)
    }

    private func timeBadge(_ event: HistoryBoundaryEvent) -> some View {
        Text(event.timeText)
            .font(.caption.monospacedDigit())
            .fontDesign(.serif)
            .bold()
            .foregroundStyle(.tint)
            .lineLimit(1)
            .minimumScaleFactor(Constants.timeMinimumScaleFactor)
            .frame(width: Constants.timeWidth)
            .frame(minHeight: Constants.timeMinimumHeight)
            .background(.background, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(
                        .quaternary,
                        lineWidth: Constants.timeBorderWidth
                    )
            }
    }

    private func eventDetails(_ event: HistoryBoundaryEvent) -> some View {
        VStack(alignment: .leading, spacing: Constants.detailSpacing) {
            Text(event.title)
                .font(.subheadline)
                .bold()
            Text(event.detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timelineRail: some View {
        Rectangle()
            .fill(.quaternary)
            .frame(width: Constants.railWidth)
            .padding(.vertical, Constants.railVerticalInset)
            .offset(x: Constants.railHorizontalOffset)
            .accessibilityHidden(true)
    }
}

#Preview {
    DynastyBoundaryEventTimeline(events: [
        HistoryBoundaryEvent(
            id: "preview-start",
            orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID,
            dateExpressionID: "preview-start-date",
            timeText: "1368",
            title: "明正统期开始",
            detail: "明从这一边界进入当前正统时间线。",
            sequenceIndex: 0
        ),
        HistoryBoundaryEvent(
            id: "preview-end",
            orthodoxPeriodID: HistoryPreviewData.orthodoxPeriodID,
            dateExpressionID: "preview-end-date",
            timeText: "1644",
            title: "明正统期结束",
            detail: "当前正统时间线在这一边界结束明时期。",
            sequenceIndex: 1
        )
    ])
    .padding()
}
