import ChineseCalendarPersistence
import SwiftData

/// 为 History 目录中的同文件 Preview 提供一套彼此关联的内存数据。
enum HistoryPreviewData {
    struct Sample {
        let tradition: OrthodoxTradition
        let dynasty: Dynasty
        let period: OrthodoxPeriod
        let emperor: Emperor
        let reignEra: ReignEra
    }

    static let dynastyID = "preview-ming"
    static let orthodoxPeriodID = "preview-ming-orthodox-period"
    static let emperorID = "preview-ming-chengzu"
    static let reignEraID = "preview-yongle"

    static let container: ModelContainer = {
        do {
            let schema = Schema(
                ChineseCalendarModelSchema.models,
                version: ChineseCalendarModelSchema.version
            )
            let configuration = ModelConfiguration(
                "HistoryPreview",
                schema: schema,
                isStoredInMemoryOnly: true
            )
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let sample = makeSample()

            container.mainContext.insert(sample.tradition)
            container.mainContext.insert(sample.dynasty)
            container.mainContext.insert(sample.period)
            try container.mainContext.save()

            return container
        } catch {
            fatalError("无法创建 History Preview 的内存 ModelContainer：\(error)")
        }
    }()

    static func makeSample() -> Sample {
        let dynasty = makeDynasty()
        let taizu = makeTaizu(dynasty: dynasty)
        let (chengzu, yongle) = makeChengzu(dynasty: dynasty)
        dynasty.emperors = [taizu, chengzu]

        let tradition = OrthodoxTradition(
            id: HistoryConfiguration.defaultOrthodoxTraditionID,
            name: "默认正统序列"
        )
        let period = makePeriod(dynasty: dynasty, tradition: tradition)

        return Sample(
            tradition: tradition,
            dynasty: dynasty,
            period: period,
            emperor: chengzu,
            reignEra: yongle
        )
    }

    private static func makeDynasty() -> Dynasty {
        let dynastyStart = date(id: "preview-ming-claimed-start", year: 1368)
        let dynastyEnd = date(id: "preview-ming-claimed-end", year: 1644)
        return Dynasty(
            id: dynastyID,
            name: "大明",
            shortName: "明",
            claimedStartDate: dynastyStart,
            claimedEndDate: dynastyEnd,
            note: "Preview 使用的明代示例资料。"
        )
    }

    private static func makeTaizu(dynasty: Dynasty) -> Emperor {
        let hongwuStart = date(id: "preview-hongwu-start", year: 1368)
        let hongwuEnd = date(id: "preview-hongwu-end", year: 1399)
        let taizu = Emperor(
            id: "preview-ming-taizu",
            dynasty: dynasty,
            displayName: "明太祖朱元璋",
            personalName: "朱元璋",
            templeName: "太祖",
            sequenceIndex: 0,
            note: "明朝开国皇帝。"
        )
        let hongwuSegment = EmperorReignSegment(
            id: "preview-hongwu-reign",
            emperor: taizu,
            sequenceIndex: 0,
            segmentIndex: 0,
            startDate: hongwuStart,
            endDate: hongwuEnd
        )
        let hongwu = ReignEra(
            id: "preview-hongwu",
            emperor: taizu,
            name: "洪武",
            normalizedName: "洪武",
            sequenceIndex: 0,
            eraIndexWithinEmperor: 0,
            startDate: hongwuStart,
            endDate: hongwuEnd
        )
        taizu.reignSegments = [hongwuSegment]
        taizu.reignEras = [hongwu]
        return taizu
    }

    private static func makeChengzu(dynasty: Dynasty) -> (Emperor, ReignEra) {
        let yongleStart = date(id: "preview-yongle-start", year: 1403)
        let yongleEnd = date(id: "preview-yongle-end", year: 1425)
        let chengzu = Emperor(
            id: emperorID,
            dynasty: dynasty,
            displayName: "明成祖朱棣",
            personalName: "朱棣",
            templeName: "成祖",
            sequenceIndex: 1,
            note: "Preview 展示庙号、本名、在位区间与年号关系。"
        )
        let yongleSegment = EmperorReignSegment(
            id: "preview-yongle-reign",
            emperor: chengzu,
            sequenceIndex: 1,
            segmentIndex: 0,
            startDate: yongleStart,
            endDate: yongleEnd
        )
        let yongle = ReignEra(
            id: reignEraID,
            emperor: chengzu,
            name: "永乐",
            normalizedName: "永乐",
            sequenceIndex: 1,
            eraIndexWithinEmperor: 0,
            startDate: yongleStart,
            endDate: yongleEnd,
            note: "建文四年七月即位，次年改元永乐。"
        )
        chengzu.reignSegments = [yongleSegment]
        chengzu.reignEras = [yongle]
        return (chengzu, yongle)
    }

    private static func makePeriod(
        dynasty: Dynasty,
        tradition: OrthodoxTradition
    ) -> OrthodoxPeriod {
        let orthodoxStartDate = date(id: "preview-ming-orthodox-start-date", year: 1368)
        let orthodoxEndDate = date(id: "preview-ming-orthodox-end-date", year: 1644)
        let startBoundary = OrthodoxBoundary(
            id: "preview-ming-orthodox-start",
            traditionID: tradition.id,
            dateExpressionID: orthodoxStartDate.id,
            tradition: tradition,
            date: orthodoxStartDate
        )
        let endBoundary = OrthodoxBoundary(
            id: "preview-ming-orthodox-end",
            traditionID: tradition.id,
            dateExpressionID: orthodoxEndDate.id,
            tradition: tradition,
            date: orthodoxEndDate
        )
        return OrthodoxPeriod(
            id: orthodoxPeriodID,
            traditionID: tradition.id,
            dynastyID: dynasty.id,
            startBoundaryID: startBoundary.id,
            endBoundaryID: endBoundary.id,
            sequenceIndex: 0,
            segmentIndex: 0,
            segmentName: dynasty.shortName ?? dynasty.name,
            tradition: tradition,
            dynasty: dynasty,
            startBoundary: startBoundary,
            endBoundary: endBoundary,
            note: "Preview 使用的正统时间线边界。"
        )
    }

    private static func date(id: String, year: Int) -> ChineseDateExpression {
        ChineseDateExpression(
            id: id,
            precision: .year,
            index: year,
            sourceText: "\(year)年"
        )
    }
}
