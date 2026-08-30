import ChineseCalendarLogging
import ChineseCalendarPersistence
import Foundation
import Observation
import SwiftData

@MainActor
@Observable
public final class ChineseCalendarStoreCoordinator {
    private(set) var state: CalendarStoreBootstrapState = .starting
    private(set) var fullStoreDownloadProgress: FullStoreDownloadProgress?
    private(set) var downloadErrorMessage: String?
    private(set) var isClearingDownloadedData = false

    @ObservationIgnored private var fullStoreDownloadTask: Task<Void, Never>?
    @ObservationIgnored private var clearCompletedDownloadTask: Task<Void, Never>?

    #if DEBUG
        @ObservationIgnored private let fullStoreDownloadSimulator: FullStoreDownloadSimulator
        private(set) var isSimulatingFullStoreDownload = false
    #endif

    private let fullStoreConfiguration: FullSeedStoreConfig?
    private let seedStoreBundle: Bundle

    public init(
        fullStoreConfiguration: FullSeedStoreConfig? = .fromBundle(),
        seedStoreBundle: Bundle = .main
    ) {
        self.fullStoreConfiguration = fullStoreConfiguration
        self.seedStoreBundle = seedStoreBundle
        #if DEBUG
            fullStoreDownloadSimulator = FullStoreDownloadSimulator()
        #endif
    }

    #if DEBUG
        init(
            fullStoreConfiguration: FullSeedStoreConfig? = .fromBundle(),
            seedStoreBundle: Bundle = .main,
            fullStoreDownloadSimulator: FullStoreDownloadSimulator
        ) {
            self.fullStoreConfiguration = fullStoreConfiguration
            self.seedStoreBundle = seedStoreBundle
            self.fullStoreDownloadSimulator = fullStoreDownloadSimulator
        }
    #endif

    func prepareStoreIfNeeded() async {
        guard case .starting = state else {
            return
        }

        prepareStore()
    }

    func prepareStore() {
        do {
            let container = try ChineseCalendarModelContainerFactory.makeSharedContainer()
            let contentLevel = try ChineseCalendarModelContainerFactory.installedStoreContentLevel() ?? .base
            let identityToken = try ChineseCalendarModelContainerFactory.installedStoreIdentityToken()
            state = .ready(container: container, contentLevel: contentLevel, identityToken: identityToken)
        } catch {
            ChineseCalendarLog.persistence.error("Failed to prepare SwiftData store: \(error.localizedDescription)")
            state = .failed(message: error.localizedDescription)
        }
    }

    @discardableResult
    func startFullStoreDownload() -> Bool {
        guard let fullStoreConfiguration,
              fullStoreDownloadTask == nil,
              !isClearingDownloadedData
        else {
            return false
        }

        downloadErrorMessage = nil
        clearCompletedDownloadTask?.cancel()
        fullStoreDownloadProgress = .preparingManifest

        fullStoreDownloadTask = Task { [fullStoreConfiguration] in
            await downloadAndInstallFullStore(configuration: fullStoreConfiguration)
        }

        return true
    }

    func canDownloadFullStore(contentLevel: ChineseCalendarSeedStoreContentLevel) -> Bool {
        fullStoreConfiguration != nil && contentLevel != .full && fullStoreDownloadTask == nil &&
            !isClearingDownloadedData
    }

    #if DEBUG
        var canStartSimulatedFullStoreDownload: Bool {
            !isSimulatingFullStoreDownload && fullStoreDownloadTask == nil &&
                fullStoreDownloadProgress == nil && !isClearingDownloadedData
        }

        @discardableResult
        func startSimulatedFullStoreDownload() -> Bool {
            guard canStartSimulatedFullStoreDownload else {
                return false
            }

            downloadErrorMessage = nil
            clearCompletedDownloadTask?.cancel()
            isSimulatingFullStoreDownload = true
            fullStoreDownloadTask = Task {
                await simulateFullStoreDownload()
            }
            return true
        }

        func cancelSimulatedFullStoreDownload() async {
            guard isSimulatingFullStoreDownload else {
                return
            }

            let activeDownloadTask = fullStoreDownloadTask
            activeDownloadTask?.cancel()
            await activeDownloadTask?.value
        }
    #endif

    func dismissDownloadError() {
        downloadErrorMessage = nil
    }

    func storeIdentity(
        contentLevel: ChineseCalendarSeedStoreContentLevel,
        identityToken: String?
    ) -> String {
        "\(contentLevel.rawValue)-\(identityToken ?? "unknown")"
    }

    func clearDownloadedData() async throws {
        guard !isClearingDownloadedData else {
            return
        }

        isClearingDownloadedData = true
        defer {
            isClearingDownloadedData = false
        }

        let activeDownloadTask = fullStoreDownloadTask
        activeDownloadTask?.cancel()
        await activeDownloadTask?.value

        clearCompletedDownloadTask?.cancel()
        clearCompletedDownloadTask = nil
        fullStoreDownloadTask = nil
        fullStoreDownloadProgress = nil

        let storeURL = try ChineseCalendarModelContainerFactory.clearDownloadedSeedStore(bundle: seedStoreBundle)
        let container = try ChineseCalendarModelContainerFactory.makeContainer(
            at: storeURL,
            allowsSave: false
        )
        let contentLevel = try ChineseCalendarModelContainerFactory.installedStoreContentLevel() ?? .base
        let identityToken = try ChineseCalendarModelContainerFactory.installedStoreIdentityToken()
        state = .ready(container: container, contentLevel: contentLevel, identityToken: identityToken)
    }

    private func downloadAndInstallFullStore(
        configuration: FullSeedStoreConfig
    ) async {
        let installer = ChineseCalendarFullSeedStoreInstaller(configuration: configuration)

        do {
            for try await event in await installer.installEvents() {
                switch event {
                case let .downloading(progress):
                    fullStoreDownloadProgress = .downloading(progress: progress)
                case .validating:
                    fullStoreDownloadProgress = .validating
                case .installing:
                    fullStoreDownloadProgress = .installing
                case let .installed(result):
                    fullStoreDownloadProgress = .completed
                    let container = try ChineseCalendarModelContainerFactory.makeContainer(
                        at: result.storeURL,
                        allowsSave: false
                    )
                    state = .ready(
                        container: container,
                        contentLevel: .full,
                        identityToken: result.manifest.artifactVersion ?? result.manifest.datasetVersion
                    )
                    fullStoreDownloadTask = nil
                    clearCompletedDownloadProgressAfterDelay()
                }
            }
        } catch {
            fullStoreDownloadTask = nil
            fullStoreDownloadProgress = nil
            if isCancellation(error) {
                return
            }

            ChineseCalendarLog.persistence
                .error("Failed to install full SwiftData store: \(error.localizedDescription)")
            showDownloadErrorIfStoreRecovers(error.localizedDescription)
        }
    }

    #if DEBUG
        private func simulateFullStoreDownload() async {
            do {
                try await fullStoreDownloadSimulator.run { progress in
                    fullStoreDownloadProgress = progress
                }
                fullStoreDownloadTask = nil
                isSimulatingFullStoreDownload = false
                clearCompletedDownloadProgressAfterDelay()
            } catch {
                fullStoreDownloadTask = nil
                isSimulatingFullStoreDownload = false
                fullStoreDownloadProgress = nil
                guard !isCancellation(error) else {
                    return
                }

                downloadErrorMessage = error.localizedDescription
            }
        }
    #endif

    private func clearCompletedDownloadProgressAfterDelay() {
        clearCompletedDownloadTask?.cancel()
        clearCompletedDownloadTask = Task {
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }

            guard fullStoreDownloadProgress?.phase == .completed else {
                return
            }

            fullStoreDownloadProgress = nil
            clearCompletedDownloadTask = nil
        }
    }

    private func showDownloadErrorIfStoreRecovers(_ message: String) {
        do {
            let container = try ChineseCalendarModelContainerFactory.makeSharedContainer()
            let contentLevel = try ChineseCalendarModelContainerFactory.installedStoreContentLevel() ?? .base
            let identityToken = try ChineseCalendarModelContainerFactory.installedStoreIdentityToken()
            state = .ready(container: container, contentLevel: contentLevel, identityToken: identityToken)
            downloadErrorMessage = message
        } catch {
            ChineseCalendarLog.persistence.error("Failed to recover SwiftData store: \(error.localizedDescription)")
            downloadErrorMessage = nil
            state = .failed(message: message)
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError || Task.isCancelled {
            return true
        }

        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
    }
}

enum CalendarStoreBootstrapState {
    case starting
    case ready(
        container: ModelContainer,
        contentLevel: ChineseCalendarSeedStoreContentLevel,
        identityToken: String?
    )
    case failed(message: String)
}
