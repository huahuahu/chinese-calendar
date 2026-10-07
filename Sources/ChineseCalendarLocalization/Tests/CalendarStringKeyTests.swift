@testable import ChineseCalendarLocalization
import Foundation
import Testing

struct CalendarStringKeyTests {
    @Test func catalogUsesThePackageBundleAndChineseFallback() throws {
        let resource = CalendarStringKey.History.ReignEraList.Empty.title
        #expect(resource.table == "Calendar")
        let url = try #require(Bundle.module.url(
            forResource: "Calendar", withExtension: "strings", subdirectory: nil, localization: "zh-Hans"
        ))
        let values = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
        let strings = try #require(values as? [String: String])
        #expect(strings[resource.key] == "没有年号资料")
        #expect(localized(resource, locale: "zh-Hans") == "没有年号资料")
        #expect(localized(resource, locale: "fr-FR") == "没有年号资料")
    }

    @Test(arguments: [(0.0, "0%"), (0.5, "50%"), (1.0, "100%")])
    func downloadInterpolationUsesPercent(progress: Double, expected: String) {
        let resource = CalendarStringKey.Store.Download.Downloading.detail(progress: progress)
        #expect(localized(resource) == "文件已下载 \(expected)。")
    }

    @Test func fixedDebugPercentagesKeepOnePercentSign() {
        #expect(localized(CalendarStringKey.Settings.Debug.DownloadPreview.downloadStarted) == "下载（0%）")
        #expect(localized(CalendarStringKey.Settings.Debug.DownloadPreview.downloading) == "下载（50%）")
        #expect(localized(CalendarStringKey.Settings.Debug.DownloadPreview.downloadFinished) == "下载（100%，尚未校验）")
    }

    @Test func nestedResourcePreservesThePhaseTitle() {
        let resource = CalendarStringKey.Store.Download.Progress.stage(
            step: 2, count: 5, title: CalendarStringKey.Store.Download.Downloading.title
        )
        #expect(localized(resource) == "第 2/5 步 · 下载文件")
    }

    @Test(arguments: [0, 1, 12])
    func countsKeepEveryArgument(count: Int) {
        let resource = CalendarStringKey.History.EmperorList.summary(emperorCount: count, segmentCount: 24)
        #expect(localized(resource) == "\(count) 位皇帝 · 24 段纪年")
        #expect(localized(CalendarStringKey.History.ReignEraList.summary(count: count, boundary: "前1—1"))
            == "\(count) 个年号 · 前1—1")
    }

    @Test func accessibilityKeepsNamesAndTodaySeparate() {
        let resource = CalendarStringKey.Calendar.MonthGrid.Day.todayAccessibilityLabel(
            day: "十五", stemBranch: "戊寅", civilDate: "2026年10月6日"
        )
        #expect(localized(resource) == "十五，今天，日干支，戊寅，2026年10月6日")
        let names = CalendarStringKey.Common.List.names(["洪武", "永乐"], locale: Locale(identifier: "zh-Hans"))
        #expect(names.contains("洪武"))
        #expect(names.contains("永乐"))
        #expect(localized(CalendarStringKey.History.EmperorCard.eraNamesAccessibilityLabel(names: names))
            == "年号：\(names)")
    }

    @Test func datePrecisionPreservesBoundsAndIndices() {
        #expect(localized(CalendarStringKey.Common.DatePrecision.indexed(precision: "日精度", index: 12345))
            == "日精度 · index 12345")
        #expect(localized(CalendarStringKey.Common.DatePrecision.bounds(lower: "年精度 220", upper: "年精度 221"))
            == "范围精度 · 年精度 220 到 年精度 221")
    }

    private func localized(_ resource: LocalizedStringResource, locale: String = "zh-Hans") -> String {
        var resource = resource
        resource.locale = Locale(identifier: locale)
        return String(localized: resource)
    }
}
