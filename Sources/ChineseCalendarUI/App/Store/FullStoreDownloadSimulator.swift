#if DEBUG
import Foundation

@MainActor
struct FullStoreDownloadSimulator {
    typealias Sleep = @MainActor (Duration) async throws -> Void
    typealias EventHandler = @MainActor (FullStoreDownloadProgress) -> Void

    private let sleep: Sleep

    init(
        sleep: @escaping Sleep = { duration in
            try await Task.sleep(for: duration)
        }
    ) {
        self.sleep = sleep
    }

    func run(eventHandler: EventHandler) async throws {
        try Task.checkCancellation()
        eventHandler(.preparingManifest)
        try await wait(for: .milliseconds(500))

        eventHandler(.downloading(progress: 0))
        for step in 1 ... 50 {
            try await wait(for: .milliseconds(200))
            eventHandler(.downloading(progress: Double(step) / 50))
        }

        eventHandler(.validating)
        try await wait(for: .milliseconds(750))

        eventHandler(.installing)
        try await wait(for: .milliseconds(750))

        eventHandler(.completed)
    }

    private func wait(for duration: Duration) async throws {
        try await sleep(duration)
        try Task.checkCancellation()
    }
}
#endif
