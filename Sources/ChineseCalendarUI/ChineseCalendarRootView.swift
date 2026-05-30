import ChineseCalendarLogging
import ChineseCalendarPersistence
import SwiftData
import SwiftUI

@MainActor
public struct ChineseCalendarRootView: View {
    @State private var state: CalendarStoreBootstrapState = .starting
    @State private var downloadErrorMessage: String?

    private let fullStoreConfiguration: FullSeedStoreConfig?

    public init(
        fullStoreConfiguration: FullSeedStoreConfig? = .fromBundle()
    ) {
        self.fullStoreConfiguration = fullStoreConfiguration
    }

    public var body: some View {
        Group {
            switch state {
            case .starting:
                CalendarStoreProgressView(title: "正在准备日历数据", progress: nil)
            case let .ready(container, contentLevel, datasetVersion):
                CalendarHomeView()
                    .modelContainer(container)
                    .id(storeIdentity(contentLevel: contentLevel, datasetVersion: datasetVersion))
                    .safeAreaInset(edge: .bottom) {
                        if canDownloadFullStore(contentLevel: contentLevel) {
                            FullStoreDownloadBanner(action: startFullStoreDownload)
                        }
                    }
            case let .downloading(progress):
                CalendarStoreProgressView(title: "正在下载完整日历数据", progress: progress)
            case .validating:
                CalendarStoreProgressView(title: "正在校验完整日历数据", progress: nil)
            case .installing:
                CalendarStoreProgressView(title: "正在安装完整日历数据", progress: nil)
            case let .failed(message):
                CalendarStoreFailureView(message: message, retry: prepareStore)
            }
        }
        .task {
            await prepareStoreIfNeeded()
        }
        .alert("完整数据下载失败", isPresented: downloadErrorIsPresented) {
            Button("好", role: .cancel) {}
        } message: {
            Text(downloadErrorMessage ?? "请稍后再试。")
        }
    }

    private var downloadErrorIsPresented: Binding<Bool> {
        Binding(
            get: { downloadErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    downloadErrorMessage = nil
                }
            }
        )
    }

    private func prepareStoreIfNeeded() async {
        guard case .starting = state else {
            return
        }

        prepareStore()
    }

    private func prepareStore() {
        do {
            let container = try ChineseCalendarModelContainerFactory.makeSharedContainer()
            let contentLevel = try ChineseCalendarModelContainerFactory.installedStoreContentLevel() ?? .base
            let datasetVersion = try ChineseCalendarModelContainerFactory.installedStoreDatasetVersion()
            state = .ready(container: container, contentLevel: contentLevel, datasetVersion: datasetVersion)
        } catch {
            ChineseCalendarLog.persistence.error("Failed to prepare SwiftData store: \(error.localizedDescription)")
            state = .failed(message: error.localizedDescription)
        }
    }

    private func startFullStoreDownload() {
        guard let fullStoreConfiguration else {
            return
        }

        state = .downloading(progress: nil)

        Task {
            await downloadAndInstallFullStore(configuration: fullStoreConfiguration)
        }
    }

    private func downloadAndInstallFullStore(
        configuration: FullSeedStoreConfig
    ) async {
        let installer = ChineseCalendarFullSeedStoreInstaller(configuration: configuration)

        do {
            for try await event in await installer.installEvents() {
                switch event {
                case let .downloading(progress):
                    state = .downloading(progress: progress)
                case .validating:
                    state = .validating
                case .installing:
                    state = .installing
                case let .installed(result):
                    let container = try ChineseCalendarModelContainerFactory.makeContainer(
                        at: result.storeURL,
                        allowsSave: false
                    )
                    state = .ready(
                        container: container,
                        contentLevel: .full,
                        datasetVersion: result.manifest.datasetVersion
                    )
                }
            }
        } catch {
            ChineseCalendarLog.persistence
                .error("Failed to install full SwiftData store: \(error.localizedDescription)")
            downloadErrorMessage = error.localizedDescription
            prepareStore()
        }
    }

    private func canDownloadFullStore(contentLevel: ChineseCalendarSeedStoreContentLevel) -> Bool {
        fullStoreConfiguration != nil && contentLevel != .full
    }

    private func storeIdentity(
        contentLevel: ChineseCalendarSeedStoreContentLevel,
        datasetVersion: String?
    ) -> String {
        "\(contentLevel.rawValue)-\(datasetVersion ?? "unknown")"
    }
}

private enum CalendarStoreBootstrapState {
    case starting
    case ready(
        container: ModelContainer,
        contentLevel: ChineseCalendarSeedStoreContentLevel,
        datasetVersion: String?
    )
    case downloading(progress: Double?)
    case validating
    case installing
    case failed(message: String)
}

private struct FullStoreDownloadBanner: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("可下载完整日期数据", systemImage: "arrow.down.circle")
                .font(.callout)

            Spacer(minLength: 12)

            Button("下载", systemImage: "arrow.down", action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

private struct CalendarStoreProgressView: View {
    let title: String
    let progress: Double?

    var body: some View {
        VStack(spacing: 16) {
            if let progress {
                ProgressView(value: progress)
                    .frame(maxWidth: 320)
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }

            Text(title)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct CalendarStoreFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("无法打开日历数据", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        } actions: {
            Button("重试", systemImage: "arrow.clockwise", action: retry)
        }
    }
}

#Preview {
    ChineseCalendarRootView(fullStoreConfiguration: nil)
}
