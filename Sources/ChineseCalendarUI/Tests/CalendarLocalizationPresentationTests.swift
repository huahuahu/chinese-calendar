import ChineseCalendarLocalization
import ChineseCalendarPersistence
@testable import ChineseCalendarUI
import Foundation
import Testing

@MainActor
struct CalendarLocalizationPresentationTests {
    @Test func datePrecisionMapsToLocalizedResources() {
        let cases: [(ChineseDatePrecision, String)] = [
            (.year, "年精度"), (.month, "月精度"), (.day, "日精度"),
            (.range, "范围精度"), (.unknown, "精度未知")
        ]
        for (precision, expected) in cases {
            #expect(localized(CalendarDatePrecisionPresentation.title(for: precision)) == expected)
        }
    }

    @Test func errorMappingDoesNotExposeTechnicalDescriptions() {
        let cases: [(Error, LocalizedStringResource)] = [
            (URLError(.notConnectedToInternet), CalendarStringKey.Store.Error.network),
            (URLError(.timedOut), CalendarStringKey.Store.Error.timedOut),
            (CocoaError(.fileWriteOutOfSpace), CalendarStringKey.Store.Error.storage),
            (CocoaError(.fileReadNoPermission), CalendarStringKey.Store.Error.permission),
            (
                ChineseCalendarStoreError.missingSeedResource("private.sqlite"),
                CalendarStringKey.Store.Error.missingResource
            ),
            (
                ChineseCalendarFullSeedStoreInstallError.checksumMismatch(expected: "secret", actual: "bad"),
                CalendarStringKey.Store.Error.invalidFile
            ),
            (
                ChineseCalendarFullSeedStoreInstallError.unsupportedSchemaVersion("2", expected: "1"),
                CalendarStringKey.Store.Error.incompatible
            ),
            (
                ChineseCalendarFullSeedStoreInstallError.rangeNotSatisfiable,
                CalendarStringKey.Store.Error.expiredDownload
            )
        ]
        for (error, expected) in cases {
            let message = CalendarStoreErrorPresentation.message(for: error, operation: .download)
            #expect(localized(message) == localized(expected))
        }
        let unknown = NSError(domain: "test", code: 42, userInfo: [NSLocalizedDescriptionKey: "private path"])
        #expect(localized(CalendarStoreErrorPresentation.message(for: unknown, operation: .prepare))
            == localized(CalendarStringKey.Store.Error.prepare))
        #expect(localized(CalendarStoreErrorPresentation.message(for: unknown, operation: .clear))
            == localized(CalendarStringKey.Store.Error.clear))
        #expect(localized(CalendarStoreErrorPresentation.message(
            for: ChineseCalendarFullSeedStoreInstallError.downloadFailed(503), operation: .download
        )) == "下载服务暂时不可用（HTTP 503），请稍后重试。")
    }

    @Test func structuredFailureKeepsOnlyRecoveryCategoryAndRequiredParameters() {
        let first = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "private source A"]
        )
        let second = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorCannotConnectToHost,
            userInfo: [NSLocalizedDescriptionKey: "private source B"]
        )
        #expect(CalendarStoreErrorPresentation.failure(for: first, operation: .download) == .network)
        #expect(CalendarStoreErrorPresentation.failure(for: second, operation: .download) == .network)
        #expect(CalendarStoreErrorPresentation.failure(
            for: ChineseCalendarFullSeedStoreInstallError.downloadFailed(503), operation: .download
        ) == .server(status: 503))
        #expect(CalendarStoreErrorPresentation.failure(
            for: ChineseCalendarFullSeedStoreInstallError.checksumMismatch(expected: "secret", actual: "bad"),
            operation: .download
        ) == .invalidFile)
    }

    private func localized(_ resource: LocalizedStringResource, locale: String = "zh-Hans") -> String {
        var resource = resource
        resource.locale = Locale(identifier: locale)
        return String(localized: resource)
    }
}
