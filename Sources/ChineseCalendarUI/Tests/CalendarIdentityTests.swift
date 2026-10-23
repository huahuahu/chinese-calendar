@testable import ChineseCalendarUI
import Testing

@Suite("业务路由保持值语义")
struct CalendarIdentityTests {
    @Test func errorRoutesKeepValueSemanticsWithoutMessageIdentity() {
        let first = CalendarAlert.downloadFailed(failure: .server(status: 503))
        let same = CalendarAlert.downloadFailed(failure: .server(status: 503))
        let different = CalendarAlert.downloadFailed(failure: .server(status: 404))
        #expect(first == same)
        #expect(first != different)
        #expect(first != .clearDataFailed(failure: .server(status: 503)))
        #expect(Set([first, same, different]).count == 2)
    }

    @Test @MainActor func yearPickerDestinationDescribesThePageWithoutSessionIdentity() {
        #expect(CalendarDestination.yearPicker.id == "year-picker")
        #expect(CalendarDestination.yearPicker == .yearPicker)
    }

    #if DEBUG
        @Test @MainActor func downloadPreviewDestinationsDescribeTheirPagesWithoutSessionIdentity() {
            let destinations: [CalendarDestination] = [
                .downloadPreview, .downloadPreviewScenarios, .downloadPreviewDetails
            ]
            #expect(destinations.map(\.id) == [
                "download-preview", "download-preview-scenarios", "download-preview-details"
            ])
            #expect(Set(destinations).count == 3)
        }
    #endif
}
