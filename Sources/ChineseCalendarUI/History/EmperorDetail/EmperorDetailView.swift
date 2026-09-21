import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示在皇帝路由目的地中，用于展示姓名、在位区间和年号详情。
struct EmperorDetailView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let contentSpacing: CGFloat = 24
        static let gridSpacing: CGFloat = 12
        static let sectionSpacing: CGFloat = 12
        static let maximumContentWidth: CGFloat = 760
        static let minimumGridItemWidth: CGFloat = 140
        static let headerSpacing: CGFloat = 8
        static let metricSpacing: CGFloat = 6
        static let metricCornerRadius: CGFloat = 12
        static let detailCardSpacing: CGFloat = 10
        static let detailCardCornerRadius: CGFloat = 16
        static let dateLineSpacing: CGFloat = 4
    }

    @Query private var emperors: [Emperor]

    init(emperorID: String) {
        let emperorID = emperorID
        _emperors = Query(
            filter: #Predicate<Emperor> { emperor in
                emperor.id == emperorID
            }
        )
    }

    var body: some View {
        pageContent
    }

    @ViewBuilder
    private var pageContent: some View {
        if let emperor {
            emperorDetailPage(emperor)
        } else {
            missingEmperorState
        }
    }

    private var emperor: Emperor? {
        emperors.first
    }

    private var metricColumns: [GridItem] {
        [
            GridItem(
                .adaptive(minimum: Constants.minimumGridItemWidth),
                spacing: Constants.gridSpacing
            )
        ]
    }
}

private extension EmperorDetailView {
    private func emperorDetailPage(_ emperor: Emperor) -> some View {
        let reignSegments = sortedReignSegments(for: emperor)
        let reignEras = sortedReignEras(for: emperor)

        return ScrollView {
            VStack(alignment: .leading, spacing: Constants.contentSpacing) {
                emperorIdentityHeader(emperor)
                overviewMetrics(
                    emperor: emperor,
                    reignSegmentCount: reignSegments.count,
                    reignEraCount: reignEras.count
                )
                nameDetailsSection(emperor)
                reignSegmentsSection(reignSegments)
                reignErasSection(reignEras)
            }
            .padding()
            .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
        }
        .navigationTitle(emperor.displayName)
    }

    private func sortedReignSegments(for emperor: Emperor) -> [EmperorReignSegment] {
        emperor.reignSegments.sorted {
            ($0.sequenceIndex, $0.segmentIndex, $0.id) < ($1.sequenceIndex, $1.segmentIndex, $1.id)
        }
    }

    private func sortedReignEras(for emperor: Emperor) -> [ReignEra] {
        emperor.reignEras.sorted {
            ($0.eraIndexWithinEmperor, $0.sequenceIndex, $0.id) < ($1.eraIndexWithinEmperor, $1.sequenceIndex, $1.id)
        }
    }

    private func emperorIdentityHeader(_ emperor: Emperor) -> some View {
        VStack(alignment: .leading, spacing: Constants.headerSpacing) {
            Text(emperor.displayName)
                .font(.largeTitle)
                .bold()

            Text(emperor.dynasty.name)
                .font(.headline)
                .foregroundStyle(.secondary)

            if let note = emperor.note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func overviewMetrics(
        emperor: Emperor,
        reignSegmentCount: Int,
        reignEraCount: Int
    ) -> some View {
        LazyVGrid(
            columns: metricColumns,
            alignment: .leading,
            spacing: Constants.gridSpacing
        ) {
            metricCard(title: "朝代", value: emperor.dynasty.shortName ?? emperor.dynasty.name)
            metricCard(title: "在位", value: "\(reignSegmentCount) 段")
            metricCard(title: "年号", value: "\(reignEraCount) 个")
        }
    }

    @ViewBuilder
    private func nameDetailsSection(_ emperor: Emperor) -> some View {
        if emperor.personalName != nil || emperor.templeName != nil || emperor.posthumousName != nil {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                sectionTitle("称号")

                LazyVGrid(
                    columns: metricColumns,
                    alignment: .leading,
                    spacing: Constants.gridSpacing
                ) {
                    if let personalName = emperor.personalName {
                        metricCard(title: "本名", value: personalName)
                    }

                    if let templeName = emperor.templeName {
                        metricCard(title: "庙号", value: templeName)
                    }

                    if let posthumousName = emperor.posthumousName {
                        metricCard(title: "谥号/称号", value: posthumousName)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func reignSegmentsSection(_ reignSegments: [EmperorReignSegment]) -> some View {
        if !reignSegments.isEmpty {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                sectionTitle("在位区间")

                ForEach(reignSegments, id: \.id, content: reignSegmentCard)
            }
        }
    }

    @ViewBuilder
    private func reignErasSection(_ reignEras: [ReignEra]) -> some View {
        if !reignEras.isEmpty {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                sectionTitle("年号")

                ForEach(reignEras, id: \.id, content: reignEraCard)
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .bold()
    }

    private func metricCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: Constants.metricSpacing) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            .background.secondary,
            in: .rect(cornerRadius: Constants.metricCornerRadius)
        )
        .accessibilityElement(children: .combine)
    }

    private func reignSegmentCard(_ segment: EmperorReignSegment) -> some View {
        VStack(alignment: .leading, spacing: Constants.detailCardSpacing) {
            Text(reignSegmentTitle(segment))
                .font(.headline)

            dateDetail(title: "开始", date: segment.startDate)
            dateDetail(title: "结束", date: segment.endDate)

            if let note = segment.note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.detailCardCornerRadius)
        )
        .accessibilityElement(children: .combine)
    }

    private func reignEraCard(_ era: ReignEra) -> some View {
        VStack(alignment: .leading, spacing: Constants.detailCardSpacing) {
            Text(era.name)
                .font(.headline)

            dateDetail(title: "开始", date: era.startDate)
            dateDetail(title: "结束", date: era.endDate)

            if let note = era.note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            .background.secondary,
            in: RoundedRectangle(cornerRadius: Constants.detailCardCornerRadius)
        )
        .accessibilityElement(children: .combine)
    }

    private func dateDetail(title: String, date: ChineseDateExpression) -> some View {
        VStack(alignment: .leading, spacing: Constants.dateLineSpacing) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(date.sourceText)
                .font(.subheadline)

            Text(precisionText(for: date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var missingEmperorState: some View {
        ContentUnavailableView {
            Label("没有找到皇帝", systemSymbol: .personCropCircleBadgeQuestionmark)
        } description: {
            Text("这个皇帝记录不在当前 SwiftData store 中。")
        }
    }

    private func reignSegmentTitle(_ segment: EmperorReignSegment) -> String {
        guard let segmentName = segment.segmentName else {
            return "第 \(segment.segmentIndex + 1) 段在位"
        }

        return segmentName
    }

    private func precisionText(for date: ChineseDateExpression) -> String {
        switch date.precision {
        case .year:
            indexText(prefix: "年精度", date: date)
        case .month:
            indexText(prefix: "月精度", date: date)
        case .day:
            indexText(prefix: "日精度", date: date)
        case .range:
            "范围精度"
        case .unknown:
            "精度未知"
        }
    }

    private func indexText(prefix: String, date: ChineseDateExpression) -> String {
        guard let index = date.index else {
            return prefix
        }

        return "\(prefix) · index \(index)"
    }
}

#Preview {
    NavigationStack {
        EmperorDetailView(emperorID: HistoryPreviewData.emperorID)
    }
    .modelContainer(HistoryPreviewData.container)
}
