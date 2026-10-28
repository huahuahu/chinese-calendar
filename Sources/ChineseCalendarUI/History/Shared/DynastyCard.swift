import SFSafeSymbols
import SwiftUI

struct DynastyCard: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let rowSpacing: CGFloat = 12
        static let timelineWidth: CGFloat = 12
        static let timelineMarkerSize: CGFloat = 8
        static let timelineLineWidth: CGFloat = 1
        static let dateCenterOffset: CGFloat = 8
        static let contentSpacing: CGFloat = 4
        static let disclosureMinimumSpacing: CGFloat = 8
        static let minimumRowHeight: CGFloat = 86
        static let trailingPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 12
        static let separatorPixelWidth: CGFloat = 1
    }

    let model: DynastyCardModel
    let showsDisclosureIndicator: Bool
    var connectsToPrevious = false
    var connectsToNext = false
    @ScaledMetric(relativeTo: .caption) private var dateCenterOffset: CGFloat = Constants.dateCenterOffset
    @Environment(\.displayScale) private var displayScale

    var body: some View {
        HStack(alignment: .center, spacing: Constants.rowSpacing) {
            dynastyDetails

            Spacer(minLength: Constants.disclosureMinimumSpacing)

            if showsDisclosureIndicator {
                disclosureIndicator
            }
        }
        .padding(.leading, Constants.timelineWidth + Constants.rowSpacing)
        .padding(.trailing, Constants.trailingPadding)
        .padding(.vertical, Constants.verticalPadding)
        .frame(maxWidth: .infinity, minHeight: Constants.minimumRowHeight, alignment: .topLeading)
        .background(alignment: .leading) {
            timelineTrack
        }
        .overlay(alignment: .bottom) {
            if connectsToNext {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: Constants.separatorPixelWidth / displayScale)
                    .padding(.leading, Constants.timelineWidth + Constants.rowSpacing)
                    .padding(.trailing, Constants.trailingPadding)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(model.accessibilityLabel)
    }

    private var timelineTrack: some View {
        GeometryReader { geometry in
            let markerY = Constants.verticalPadding + dateCenterOffset
            let markerX = Constants.timelineWidth / 2

            Path { path in
                path.move(to: CGPoint(x: markerX, y: connectsToPrevious ? 0 : markerY))
                path.addLine(to: CGPoint(x: markerX, y: connectsToNext ? geometry.size.height : markerY))
            }
            .stroke(.quaternary, lineWidth: Constants.timelineLineWidth)

            Circle()
                .fill(.tint)
                .frame(width: Constants.timelineMarkerSize, height: Constants.timelineMarkerSize)
                .position(x: markerX, y: markerY)
        }
        .frame(width: Constants.timelineWidth)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var dynastyDetails: some View {
        VStack(alignment: .leading, spacing: Constants.contentSpacing) {
            Text(model.boundaryText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            Text(model.dynastyName)
                .font(.title3)
                .fontWeight(.semibold)

            if let statisticsText = model.statisticsText {
                Text(statisticsText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let unavailableText = model.unavailableText {
                Text(unavailableText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var disclosureIndicator: some View {
        Image(systemSymbol: .chevronRight)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
    }
}

#Preview("朝代单行") {
    DynastyCard(
        model: DynastyCardModel(
            id: "ming",
            dynastyName: "明",
            boundaryText: "1368—1644",
            statisticsText: "16 位皇帝 · 17 个年号"
        ),
        showsDisclosureIndicator: true
    )
    .padding()
}

#Preview("首尾与连续节点") {
    VStack(spacing: 0) {
        DynastyCard(
            model: DynastyCardModel(
                id: "qin",
                dynastyName: "秦",
                boundaryText: "前221—前206",
                statisticsText: "3 位皇帝 · 0 个年号"
            ),
            showsDisclosureIndicator: true,
            connectsToNext: true
        )
        DynastyCard(
            model: DynastyCardModel(
                id: "western-han",
                dynastyName: "西汉",
                boundaryText: "前206—8",
                statisticsText: "13 位皇帝 · 43 个年号"
            ),
            showsDisclosureIndicator: true,
            connectsToPrevious: true,
            connectsToNext: true
        )
        DynastyCard(
            model: DynastyCardModel(
                id: "xin",
                dynastyName: "新",
                boundaryText: "8—23",
                statisticsText: "1 位皇帝 · 3 个年号"
            ),
            showsDisclosureIndicator: true,
            connectsToPrevious: true
        )
    }
    .padding()
}
