import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

struct EmperorDetailView: View {
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
        if let emperor {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(for: emperor)

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        DynastyFactCard(title: "朝代", value: emperor.dynasty.shortName ?? emperor.dynasty.name)
                        DynastyFactCard(title: "在位", value: "\(reignSegments.count) 段")
                        DynastyFactCard(title: "年号", value: "\(reignEras.count) 个")
                    }

                    nameSection(for: emperor)

                    if !reignSegments.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("在位区间")

                            ForEach(reignSegments, id: \.id) { segment in
                                reignSegmentCard(segment)
                            }
                        }
                    }

                    if !reignEras.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionTitle("年号")

                            ForEach(reignEras, id: \.id) { era in
                                reignEraCard(era)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 760, alignment: .leading)
            }
            .navigationTitle(emperor.displayName)
        } else {
            ContentUnavailableView {
                Label("没有找到皇帝", systemSymbol: .personCropCircleBadgeQuestionmark)
            } description: {
                Text("这个皇帝记录不在当前 SwiftData store 中。")
            }
        }
    }

    private var emperor: Emperor? {
        emperors.first
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 12)]
    }

    private var reignSegments: [EmperorReignSegment] {
        emperor?.reignSegments.sorted {
            ($0.sequenceIndex, $0.segmentIndex, $0.id) < ($1.sequenceIndex, $1.segmentIndex, $1.id)
        } ?? []
    }

    private var reignEras: [ReignEra] {
        emperor?.reignEras.sorted {
            ($0.eraIndexWithinEmperor, $0.sequenceIndex, $0.id) < ($1.eraIndexWithinEmperor, $1.sequenceIndex, $1.id)
        } ?? []
    }

    private func header(for emperor: Emperor) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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

    @ViewBuilder
    private func nameSection(for emperor: Emperor) -> some View {
        if emperor.personalName != nil || emperor.templeName != nil || emperor.posthumousName != nil {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("称号")

                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    if let personalName = emperor.personalName {
                        DynastyFactCard(title: "本名", value: personalName)
                    }

                    if let templeName = emperor.templeName {
                        DynastyFactCard(title: "庙号", value: templeName)
                    }

                    if let posthumousName = emperor.posthumousName {
                        DynastyFactCard(title: "谥号/称号", value: posthumousName)
                    }
                }
            }
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .bold()
    }

    private func reignSegmentCard(_ segment: EmperorReignSegment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(reignSegmentTitle(segment))
                .font(.headline)

            dateLine(title: "开始", date: segment.startDate)
            dateLine(title: "结束", date: segment.endDate)

            if let note = segment.note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func reignEraCard(_ era: ReignEra) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(era.name)
                .font(.headline)

            dateLine(title: "开始", date: era.startDate)
            dateLine(title: "结束", date: era.endDate)

            if let note = era.note {
                Text(note)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    private func dateLine(title: String, date: ChineseDateExpression) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
