import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Testing

@MainActor
@Test func orthodoxPeriodRangeAndSpanUsePoliticalBoundaries() {
    let start = yearExpression(id: "ming-start", year: 1368)
    let end = yearExpression(id: "ming-end", year: 1644)

    #expect(
        HistoryDateRangeFormatter.orthodoxPeriodRange(start: start, end: end)
            == "1368—1644"
    )
    #expect(HistoryDateRangeFormatter.dynastySpanYears(start: start, end: end) == 276)
}

@MainActor
@Test func usageRangeConvertsExclusiveEndToLastUsedYear() {
    let start = yearExpression(id: "yongle-start", year: 1403)
    let end = yearExpression(id: "yongle-end", year: 1425)

    #expect(
        HistoryDateRangeFormatter.usageRange(start: start, exclusiveEnd: end)
            == "1403—1424"
    )
    #expect(
        HistoryDateRangeFormatter.usageDurationYears(start: start, exclusiveEnd: end)
            == 22
    )
}

@MainActor
@Test func singleYearUsageRangeDoesNotRenderARepeatedRange() {
    let start = yearExpression(id: "hongxi-start", year: 1425)
    let end = yearExpression(id: "hongxi-end", year: 1426)

    #expect(
        HistoryDateRangeFormatter.usageRange(start: start, exclusiveEnd: end)
            == "1425"
    )
    #expect(
        HistoryDateRangeFormatter.usageDurationYears(start: start, exclusiveEnd: end)
            == 1
    )
}

@MainActor
@Test func insufficientPrecisionPreservesSourceTextAndDoesNotInventDuration() {
    let start = ChineseDateExpression(
        id: "uncertain-start",
        precision: .month,
        sourceText: "洪熙元年正月"
    )
    let end = ChineseDateExpression(
        id: "uncertain-end",
        precision: .unknown,
        sourceText: "次年六月前"
    )

    #expect(
        HistoryDateRangeFormatter.usageRange(start: start, exclusiveEnd: end)
            == "洪熙元年正月—次年六月前"
    )
    #expect(
        HistoryDateRangeFormatter.usageDurationYears(start: start, exclusiveEnd: end)
            == nil
    )
    #expect(HistoryDateRangeFormatter.dynastySpanYears(start: start, end: end) == nil)
}

@Test func importedReignEraNoteExposesOnlyTheSourceExplanation() {
    let note = "Parsed from era_names_simp.html table \"明\"; source note: 二十二年八月明仁宗即位后沿用"

    #expect(
        HistoryNoteFormatter.reignEraNote(note)
            == "二十二年八月明仁宗即位后沿用"
    )
    #expect(HistoryNoteFormatter.reignEraNote("Parsed from era_names_simp.html table \"明\".") == nil)
}

@MainActor
@Test func reignEraCardDerivesDurationFromBoundaries() {
    let dynasty = Dynasty(
        id: "ming",
        name: "明",
        claimedStartDate: yearExpression(id: "ming-claimed-start", year: 1368),
        claimedEndDate: yearExpression(id: "ming-claimed-end", year: 1644)
    )
    let emperor = Emperor(
        id: "ming-guangzong",
        dynasty: dynasty,
        displayName: "朱常洛(光宗)",
        personalName: "朱常洛",
        templeName: "光宗",
        sequenceIndex: 13
    )
    let reignEra = ReignEra(
        id: "ming-taichang",
        emperor: emperor,
        name: "泰昌",
        normalizedName: "泰昌",
        sequenceIndex: 14,
        eraIndexWithinEmperor: 0,
        startDate: yearExpression(id: "taichang-start", year: 1620),
        endDate: yearExpression(id: "taichang-end", year: 1621)
    )

    #expect(ReignEraCardModel(reignEra: reignEra).durationText == "1 年")
}

@MainActor
private func yearExpression(id: String, year: Int) -> ChineseDateExpression {
    ChineseDateExpression(
        id: id,
        precision: .year,
        index: year,
        sourceText: "\(year)"
    )
}
