@testable import ChineseCalendarUI
import Testing

@MainActor
@Test func downloadPercentageOnlyRepresentsFileTransfer() {
    #expect(FullStoreDownloadProgress.downloading(progress: 0.5).downloadFraction == 0.5)
    #expect(FullStoreDownloadProgress.downloading(progress: 0).downloadFraction == 0)
    #expect(FullStoreDownloadProgress.preparingManifest.downloadFraction == nil)
    #expect(FullStoreDownloadProgress.validating.downloadFraction == nil)
    #expect(FullStoreDownloadProgress.installing.downloadFraction == nil)
    #expect(FullStoreDownloadProgress.completed.downloadFraction == nil)
}

@MainActor
@Test func downloadedFileStillRequiresValidationAndInstallation() {
    let progress = FullStoreDownloadProgress.downloading(progress: 1)

    #expect(progress.downloadFraction == 1)
    #expect(progress.status(of: .preparingManifest) == .completed)
    #expect(progress.status(of: .downloading) == .current)
    #expect(progress.status(of: .validating) == .pending)
    #expect(progress.status(of: .installing) == .pending)
    #expect(progress.status(of: .completed) == .pending)

    #expect(FullStoreDownloadProgress.validating.status(of: .downloading) == .completed)
    #expect(FullStoreDownloadProgress.validating.status(of: .validating) == .current)
    #expect(FullStoreDownloadProgress.installing.status(of: .completed) == .pending)
    #expect(FullStoreDownloadPhase.allCases.allSatisfy {
        FullStoreDownloadProgress.completed.status(of: $0) == .completed
    })
}

@MainActor
@Test func fileProgressHandlesInvalidAndOutOfRangeValues() {
    #expect(FullStoreDownloadProgress.downloading(progress: -0.1).downloadFraction == 0)
    #expect(FullStoreDownloadProgress.downloading(progress: 1.1).downloadFraction == 1)
    #expect(FullStoreDownloadProgress.downloading(progress: .nan).downloadFraction == 0)
    #expect(FullStoreDownloadProgress.downloading(progress: .infinity).downloadFraction == 0)
}
