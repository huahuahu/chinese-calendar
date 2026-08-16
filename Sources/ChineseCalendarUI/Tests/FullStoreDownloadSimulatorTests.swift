#if DEBUG
    import ChineseCalendarPersistence
    @testable import ChineseCalendarUI
    import Foundation
    import Testing

    @MainActor
    @Test func simulatedDownloadProducesTheCompleteProgressSequenceWithoutWaiting() async throws {
        var durations: [Duration] = []
        var events: [FullStoreDownloadProgress] = []
        let simulator = FullStoreDownloadSimulator { duration in
            durations.append(duration)
        }

        try await simulator.run { progress in
            events.append(progress)
        }

        #expect(events.first == .preparingManifest)
        #expect(events.suffix(3) == [.validating, .installing, .completed])

        let downloadProgress = events.compactMap { event in
            event.phase == .downloading ? event.downloadProgress : nil
        }
        let expectedDownloadProgress = (0 ... 50).map { Double($0) / 50 }
        #expect(downloadProgress == expectedDownloadProgress)
        #expect(downloadProgress == downloadProgress.sorted())

        let expectedDurations = [Duration.milliseconds(500)]
            + Array(repeating: .milliseconds(200), count: 50)
            + [.milliseconds(750), .milliseconds(750)]
        #expect(durations == expectedDurations)
    }

    @MainActor
    @Test func simulatedDownloadObservesCancellation() async {
        let simulator = FullStoreDownloadSimulator { _ in
            try Task.checkCancellation()
        }
        let task = Task {
            try await simulator.run { _ in }
        }

        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @MainActor
    @Test func coordinatorPreventsConcurrentSimulatedAndRealDownloads() async throws {
        let simulator = FullStoreDownloadSimulator { duration in
            try await Task.sleep(for: duration)
        }
        let configuration = try FullSeedStoreConfig(
            manifestURL: #require(URL(string: "https://example.invalid/manifest.json"))
        )
        let coordinator = ChineseCalendarStoreCoordinator(
            fullStoreConfiguration: configuration,
            fullStoreDownloadSimulator: simulator
        )

        #expect(coordinator.canStartSimulatedFullStoreDownload)
        #expect(coordinator.startSimulatedFullStoreDownload())
        #expect(!coordinator.canStartSimulatedFullStoreDownload)
        #expect(!coordinator.startSimulatedFullStoreDownload())
        #expect(!coordinator.startFullStoreDownload())

        await coordinator.cancelSimulatedFullStoreDownload()

        #expect(coordinator.fullStoreDownloadProgress == nil)
        #expect(coordinator.downloadErrorMessage == nil)
        #expect(coordinator.canStartSimulatedFullStoreDownload)
    }
#endif
