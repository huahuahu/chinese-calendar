@testable import ChineseCalendarLocalization
import Foundation
import Testing

@Test func dateCatalogUsesLocalizationBundleWithoutYearGrouping() throws {
    let url = try #require(Bundle.module.url(
        forResource: "Calendar", withExtension: "strings", subdirectory: nil, localization: "zh-Hans"
    ))
    #expect(FileManager.default.fileExists(atPath: url.path))
    for locale in ["zh-Hans", "en-US"] {
        var resource = CalendarStringKey.Calendar.Date.year(number: 2026)
        resource.locale = Locale(identifier: locale)
        #expect(String(localized: resource) == "公元 2026 年")
        resource = CalendarStringKey.Calendar.Date.beforeCommonEraYear(number: 221)
        resource.locale = Locale(identifier: locale)
        #expect(String(localized: resource) == "公元前 221 年")
    }
}
