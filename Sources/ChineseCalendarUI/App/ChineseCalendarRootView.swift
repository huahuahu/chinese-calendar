import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 应用根视图，负责准备日历数据并进入主浏览界面。
@MainActor
public struct ChineseCalendarRootView: View {
    @State private var coordinator: ChineseCalendarStoreCoordinator
    @State private var isShowingDownloadDetails = false

    public init(coordinator: ChineseCalendarStoreCoordinator) {
        _coordinator = State(initialValue: coordinator)
    }

    public init(
        fullStoreConfiguration: FullSeedStoreConfig? = .fromBundle()
    ) {
        _coordinator = State(
            initialValue: ChineseCalendarStoreCoordinator(fullStoreConfiguration: fullStoreConfiguration)
        )
    }

    public var body: some View {
        Group {
            switch coordinator.state {
            case .starting:
                CalendarStoreProgressView(title: CalendarStringKey.Store.Bootstrap.preparing, progress: nil)
            case let .ready(container, contentLevel, identityToken):
                readyCalendarHome(
                    container: container,
                    contentLevel: contentLevel,
                    identityToken: identityToken
                )
            case let .failed(message):
                CalendarStoreFailureView(message: message, retry: coordinator.prepareStore)
            }
        }
        .background(.calendarSystemBackground)
        .task {
            await coordinator.prepareStoreIfNeeded()
        }
        .alert(CalendarStringKey.Store.Download.failureTitle, isPresented: downloadErrorIsPresented) {
            Button(CalendarStringKey.Common.Action.ok, role: .cancel) {}
        } message: {
            Text(coordinator.downloadErrorMessage ?? CalendarStringKey.Common.Error.retryLater)
        }
        .calendarColorSchemePreference()
        .sheet(isPresented: $isShowingDownloadDetails) {
            if let progress = coordinator.fullStoreDownloadProgress {
                FullStoreDownloadDetailView(progress: progress)
            }
        }
        .onChange(of: coordinator.fullStoreDownloadProgress) { _, progress in
            if progress == nil {
                isShowingDownloadDetails = false
            }
        }
    }

    private func readyCalendarHome(
        container: ModelContainer,
        contentLevel: ChineseCalendarSeedStoreContentLevel,
        identityToken: String?
    ) -> some View {
        CalendarHomeView(
            settingsCoordinator: coordinator,
            bottomStatusBarIsPresented: bottomStatusBarIsPresented(contentLevel: contentLevel)
        ) {
            bottomStatusBar(contentLevel: contentLevel)
        }
        .environment(\.calendarStoreContentLevel, contentLevel)
        .modelContainer(container)
        .id(coordinator.storeIdentity(contentLevel: contentLevel, identityToken: identityToken))
    }

    private func bottomStatusBarIsPresented(contentLevel: ChineseCalendarSeedStoreContentLevel) -> Bool {
        coordinator.fullStoreDownloadProgress != nil || coordinator.canDownloadFullStore(contentLevel: contentLevel)
    }

    private var downloadErrorIsPresented: Binding<Bool> {
        Binding(
            get: { coordinator.downloadErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    coordinator.dismissDownloadError()
                }
            }
        )
    }

    @ViewBuilder
    private func bottomStatusBar(contentLevel: ChineseCalendarSeedStoreContentLevel) -> some View {
        if let progress = coordinator.fullStoreDownloadProgress {
            FullStoreDownloadBottomProgressView(progress: progress) {
                isShowingDownloadDetails = true
            }
        } else if coordinator.canDownloadFullStore(contentLevel: contentLevel) {
            FullStoreDownloadBanner(action: startFullStoreDownload)
        }
    }

    private func startFullStoreDownload() {
        coordinator.startFullStoreDownload()
    }
}

/// 显示在应用根视图底部，用于提示完整数据的下载进度。
private struct FullStoreDownloadBanner: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label(CalendarStringKey.Store.Download.Banner.title, systemSymbol: .arrowDownCircle)
                .font(.callout)

            Spacer(minLength: 12)

            Button(CalendarStringKey.Store.Download.Banner.action, systemSymbol: .arrowDown, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.calendarSystemBackground)
    }
}

/// 显示在应用启动阶段，用于反馈日历数据存储的准备进度。
private struct CalendarStoreProgressView: View {
    let title: LocalizedStringResource
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
        .background(.calendarSystemBackground)
    }
}

/// 显示在应用启动失败状态中，用于说明错误并提供重试入口。
private struct CalendarStoreFailureView: View {
    let message: LocalizedStringResource
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(CalendarStringKey.Store.Bootstrap.failureTitle, systemSymbol: .externaldriveBadgeExclamationmark)
        } description: {
            Text(message)
        } actions: {
            Button(CalendarStringKey.Common.Action.retry, systemSymbol: .arrowClockwise, action: retry)
        }
        .background(.calendarSystemBackground)
    }
}

#Preview {
    ChineseCalendarRootView(fullStoreConfiguration: nil)
}

#Preview("日历数据准备失败") {
    CalendarStoreFailureView(
        message: CalendarStoreErrorPresentation.message(
            for: URLError(.notConnectedToInternet), operation: .prepare
        ),
        retry: {}
    )
}
