import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 应用根视图，负责准备日历数据并进入主浏览界面。
@MainActor
public struct ChineseCalendarRootView: View {
    @State private var coordinator: ChineseCalendarStoreCoordinator

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
                CalendarStoreProgressView(title: "正在准备日历数据", progress: nil)
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
        .alert("完整数据下载失败", isPresented: downloadErrorIsPresented) {
            Button("好", role: .cancel) {}
        } message: {
            Text(coordinator.downloadErrorMessage ?? "请稍后再试。")
        }
        .calendarColorSchemePreference()
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
            FullStoreDownloadBottomProgressView(progress: progress)
        } else if coordinator.canDownloadFullStore(contentLevel: contentLevel) {
            FullStoreDownloadBanner(action: startFullStoreDownload)
        }
    }

    private func startFullStoreDownload() {
        _ = coordinator.startFullStoreDownload()
    }
}

/// 显示在应用根视图底部，用于提示完整数据的下载进度。
private struct FullStoreDownloadBanner: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("可下载完整日期数据", systemSymbol: .arrowDownCircle)
                .font(.callout)

            Spacer(minLength: 12)

            Button("下载", systemSymbol: .arrowDown, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.calendarSystemBackground)
    }
}

/// 显示在应用启动阶段，用于反馈日历数据存储的准备进度。
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
        .background(.calendarSystemBackground)
    }
}

/// 显示在应用启动失败状态中，用于说明错误并提供重试入口。
private struct CalendarStoreFailureView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("无法打开日历数据", systemSymbol: .externaldriveBadgeExclamationmark)
        } description: {
            Text(message)
        } actions: {
            Button("重试", systemSymbol: .arrowClockwise, action: retry)
        }
        .background(.calendarSystemBackground)
    }
}

#Preview {
    ChineseCalendarRootView(fullStoreConfiguration: nil)
}
