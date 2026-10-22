@testable import ChineseCalendarUI
import Foundation
import Testing

@Suite("业务身份的值语义与类别")
struct CalendarIdentityTests {
    private let rawValue = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
    private let otherRawValue = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))

    @Test func yearPickerIdentityPreservesEqualityAndDictionaryLookup() {
        expectValueSemantics(
            YearPickerSessionID(rawValue: rawValue), matching: YearPickerSessionID(rawValue: rawValue),
            different: YearPickerSessionID(rawValue: otherRawValue)
        )
    }

    @Test func alertMessageIdentityPreservesEqualityAndDictionaryLookup() {
        let id = CalendarAlertMessageID(rawValue: rawValue)
        expectValueSemantics(
            id, matching: CalendarAlertMessageID(rawValue: rawValue),
            different: CalendarAlertMessageID(rawValue: otherRawValue)
        )
        #expect(CalendarAlert.clearDataFailed(messageID: id).messageID == id)
        #expect(CalendarAlert.downloadFailed(messageID: id).messageID == id)
    }

    @Test @MainActor func yearPickerRouteKeepsItsUUIDStringIdentity() {
        let id = YearPickerSessionID(rawValue: rawValue)
        #expect(CalendarDestination.yearPicker(sessionID: id).id == "year-picker-\(rawValue.uuidString)")
    }

    @Test func registrationKeepsCategoriesWithTheSameUnderlyingValue() {
        var ids: Set<CalendarPresentationSessionID> = [
            .yearPicker(YearPickerSessionID(rawValue: rawValue)),
            .alertMessage(CalendarAlertMessageID(rawValue: rawValue))
        ]
        #expect(ids.count == 2)
        #expect(!ids.insert(.yearPicker(YearPickerSessionID(rawValue: rawValue))).inserted)
        #if DEBUG
            #expect(ids.insert(.downloadPreview(DownloadPreviewSessionID(rawValue: rawValue))).inserted)
            #expect(ids.count == 3)
        #endif
    }

    #if DEBUG
        @Test func downloadPreviewIdentityPreservesEqualityAndDictionaryLookup() {
            expectValueSemantics(
                DownloadPreviewSessionID(rawValue: rawValue), matching: DownloadPreviewSessionID(rawValue: rawValue),
                different: DownloadPreviewSessionID(rawValue: otherRawValue)
            )
        }

        @Test @MainActor func downloadPreviewRoutesKeepTheirUUIDStringIdentities() {
            let id = DownloadPreviewSessionID(rawValue: rawValue)
            #expect(CalendarDestination.downloadPreview(sessionID: id).id == "download-preview-\(rawValue.uuidString)")
            #expect(
                CalendarDestination.downloadPreviewScenarios(sessionID: id).id
                    == "download-preview-scenarios-\(rawValue.uuidString)"
            )
            #expect(
                CalendarDestination.downloadPreviewDetails(sessionID: id).id
                    == "download-preview-details-\(rawValue.uuidString)"
            )
        }
    #endif

    private func expectValueSemantics<ID: Hashable & Sendable>(_ id: ID, matching: ID, different: ID) {
        #expect(id == matching)
        #expect(id != different)
        #expect(Set([id, matching, different]).count == 2)
        let values = [id: "retained"]
        #expect(values[matching] == "retained")
        #expect(values[different] == nil)
    }
}
