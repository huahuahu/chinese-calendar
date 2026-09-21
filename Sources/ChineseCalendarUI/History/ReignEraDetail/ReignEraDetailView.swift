import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 通过稳定 ReignEra.id 展示年号归属、实际使用区间和交接说明。
struct ReignEraDetailView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sectionSpacing: CGFloat = 26
        static let horizontalPadding: CGFloat = 18
        static let cardCornerRadius: CGFloat = 20
        static let summarySpacing: CGFloat = 9
        static let summaryHorizontalSpacing: CGFloat = 9
        static let summaryMarkerSize: CGFloat = 3
        static let compactSummarySpacing: CGFloat = 4
        static let summaryBottomPadding: CGFloat = 18
        static let separatorHeight: CGFloat = 1
        static let ownerRowSpacing: CGFloat = 12
        static let ownerBadgeSize: CGFloat = 48
        static let ownerBadgeCornerRadius: CGFloat = 16
        static let ownerMonogramCharacterCount = 1
        static let ownerDetailSpacing: CGFloat = 4
        static let ownerMinimumHeight: CGFloat = 44
        static let ownerCardPadding: CGFloat = 14
        static let borderWidth: CGFloat = 1
        static let sectionHeadingSpacing: CGFloat = 10
        static let noteRowSpacing: CGFloat = 12
        static let noteBadgeSize: CGFloat = 34
        static let noteBadgeCornerRadius: CGFloat = 12
        static let noteCardPadding: CGFloat = 16
        static let noteLeadingCornerRadius: CGFloat = 4
        static let noteTrailingCornerRadius: CGFloat = 18
        static let noteAccentWidth: CGFloat = 3
        static let noteBackgroundTintOpacity: Double = 0.12
        static let contentVerticalPadding: CGFloat = 12
        static let maximumContentWidth: CGFloat = 760
    }

    @Query private var reignEras: [ReignEra]

    init(reignEraID: String) {
        let reignEraID = reignEraID
        _reignEras = Query(
            filter: #Predicate<ReignEra> { reignEra in
                reignEra.id == reignEraID
            }
        )
    }

    var body: some View {
        pageContent
    }
}

private extension ReignEraDetailView {
    @ViewBuilder
    private var pageContent: some View {
        if let reignEra = reignEras.first {
            reignEraDetailPage(reignEra)
        } else {
            missingReignEraState
        }
    }

    private func reignEraDetailPage(_ reignEra: ReignEra) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                usageSummary(reignEra)
                emperorAttributionCard(reignEra)
                boundarySection(reignEra)
                transitionNoteSection(reignEra)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.contentVerticalPadding)
            .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
        }
        .navigationTitle(reignEra.name)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private func usageSummary(_ reignEra: ReignEra) -> some View {
        VStack(alignment: .leading, spacing: Constants.summarySpacing) {
            sectionEyebrow(summaryTitle(reignEra))

            ViewThatFits(in: .horizontal) {
                HStack(spacing: Constants.summaryHorizontalSpacing) {
                    usageRangeText(reignEra)
                    if let duration = durationText(reignEra) {
                        summaryMarker
                        usageDurationText(duration)
                    }
                }

                VStack(alignment: .leading, spacing: Constants.compactSummarySpacing) {
                    usageRangeText(reignEra)
                    if let duration = durationText(reignEra) {
                        usageDurationText(duration)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, Constants.summaryBottomPadding)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.quaternary)
                .frame(height: Constants.separatorHeight)
        }
        .accessibilityElement(children: .combine)
    }

    private func usageRangeText(_ reignEra: ReignEra) -> some View {
        Text(usageRange(reignEra))
            .font(.title2.monospacedDigit())
            .fontDesign(.serif)
            .bold()
    }

    private func usageDurationText(_ duration: String) -> some View {
        Text(duration)
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var summaryMarker: some View {
        Circle()
            .fill(.secondary)
            .frame(
                width: Constants.summaryMarkerSize,
                height: Constants.summaryMarkerSize
            )
            .accessibilityHidden(true)
    }

    private func emperorAttributionCard(_ reignEra: ReignEra) -> some View {
        HStack(spacing: Constants.ownerRowSpacing) {
            ownerMonogramBadge(reignEra)
            ownerDetails(reignEra)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: Constants.ownerMinimumHeight,
            alignment: .leading
        )
        .padding(Constants.ownerCardPadding)
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
        )
        .overlay {
            RoundedRectangle(cornerRadius: Constants.cardCornerRadius)
                .stroke(.quaternary, lineWidth: Constants.borderWidth)
        }
        .accessibilityElement(children: .combine)
    }

    private func ownerMonogramBadge(_ reignEra: ReignEra) -> some View {
        Text(ownerMonogram(reignEra))
            .font(.title3)
            .fontDesign(.serif)
            .frame(width: Constants.ownerBadgeSize, height: Constants.ownerBadgeSize)
            .foregroundStyle(.background)
            .background(
                .primary,
                in: RoundedRectangle(cornerRadius: Constants.ownerBadgeCornerRadius)
            )
            .accessibilityHidden(true)
    }

    private func ownerDetails(_ reignEra: ReignEra) -> some View {
        VStack(alignment: .leading, spacing: Constants.ownerDetailSpacing) {
            Text("所属皇帝")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(ownerText(reignEra))
                .font(.headline)
            Text("\(dynastyName(reignEra))朝皇帝序列")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func boundarySection(_ reignEra: ReignEra) -> some View {
        VStack(alignment: .leading, spacing: Constants.sectionHeadingSpacing) {
            sectionEyebrow("使用区间")

            Text("纪年边界")
                .font(.title2)
                .bold()

            ReignEraBoundaryCard(
                startValue: HistoryDateRangeFormatter.boundaryText(reignEra.startDate),
                startPrecision: HistoryDateRangeFormatter.precisionText(reignEra.startDate),
                endValue: HistoryDateRangeFormatter.exclusiveEndBoundaryText(reignEra.endDate),
                endPrecision: HistoryDateRangeFormatter.precisionText(reignEra.endDate)
            )
        }
    }

    @ViewBuilder
    private func transitionNoteSection(_ reignEra: ReignEra) -> some View {
        if let note = HistoryNoteFormatter.reignEraNote(reignEra.note) {
            VStack(alignment: .leading, spacing: Constants.sectionHeadingSpacing) {
                sectionEyebrow("沿革说明")

                Text("年号交接")
                    .font(.title2)
                    .bold()

                transitionNoteCard(note)
            }
        }
    }

    private func transitionNoteCard(_ note: String) -> some View {
        HStack(alignment: .top, spacing: Constants.noteRowSpacing) {
            transitionNoteBadge

            Text(note)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.noteCardPadding)
        .background(
            .tint.opacity(Constants.noteBackgroundTintOpacity),
            in: UnevenRoundedRectangle(
                topLeadingRadius: Constants.noteLeadingCornerRadius,
                bottomLeadingRadius: Constants.noteLeadingCornerRadius,
                bottomTrailingRadius: Constants.noteTrailingCornerRadius,
                topTrailingRadius: Constants.noteTrailingCornerRadius
            )
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(.tint)
                .frame(width: Constants.noteAccentWidth)
        }
        .accessibilityElement(children: .combine)
    }

    private var transitionNoteBadge: some View {
        Text("记")
            .font(.caption)
            .fontDesign(.serif)
            .bold()
            .foregroundStyle(.white)
            .frame(width: Constants.noteBadgeSize, height: Constants.noteBadgeSize)
            .background(
                .tint,
                in: RoundedRectangle(cornerRadius: Constants.noteBadgeCornerRadius)
            )
            .accessibilityHidden(true)
    }

    private func sectionEyebrow(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .bold()
            .foregroundStyle(.tint)
    }

    private var missingReignEraState: some View {
        ContentUnavailableView {
            Label("没有找到年号", systemSymbol: .timelineSelection)
        } description: {
            Text("这个年号记录不在当前 SwiftData store 中。")
        }
    }

    private func summaryTitle(_ reignEra: ReignEra) -> String {
        let dynasty = reignEra.emperor.dynasty
        return "\(dynasty.shortName ?? dynasty.name) · 第 \(reignEra.sequenceIndex + 1) 个年号"
    }

    private func usageRange(_ reignEra: ReignEra) -> String {
        HistoryDateRangeFormatter.usageRange(
            start: reignEra.startDate,
            exclusiveEnd: reignEra.endDate
        )
    }

    private func durationText(_ reignEra: ReignEra) -> String? {
        HistoryDateRangeFormatter.usageDurationYears(
            start: reignEra.startDate,
            exclusiveEnd: reignEra.endDate
        ).map { "\($0) 年" }
    }

    private func ownerText(_ reignEra: ReignEra) -> String {
        ReignEraCardModel(reignEra: reignEra).emperorText
    }

    private func dynastyName(_ reignEra: ReignEra) -> String {
        let dynasty = reignEra.emperor.dynasty
        return dynasty.shortName ?? dynasty.name
    }

    private func ownerMonogram(_ reignEra: ReignEra) -> String {
        let title = reignEra.emperor.templeName
            ?? reignEra.emperor.posthumousName
            ?? reignEra.emperor.personalName
            ?? reignEra.emperor.displayName
        return String(title.prefix(Constants.ownerMonogramCharacterCount))
    }
}

#Preview {
    NavigationStack {
        ReignEraDetailView(reignEraID: HistoryPreviewData.reignEraID)
    }
    .modelContainer(HistoryPreviewData.container)
}
