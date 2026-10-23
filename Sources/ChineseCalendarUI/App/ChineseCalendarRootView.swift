import ChineseCalendarLocalization
import ChineseCalendarPersistence
import NavigationCore
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 应用根视图，负责准备日历数据并进入主浏览界面。
@MainActor
public struct ChineseCalendarRootView: View {
    @State private var coordinator: ChineseCalendarStoreCoordinator
    @State private var homeCoordinator = CalendarHomeCoordinator()

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
            case .ready:
                NavigationRootView(context: homeCoordinator.router.navigation.rootPresentation)
            case let .failed(message):
                CalendarStoreFailureView(message: message, retry: coordinator.prepareStore)
            }
        }
        .background(.calendarSystemBackground)
        .task {
            await coordinator.prepareStoreIfNeeded()
        }
        .calendarColorSchemePreference()
        .calendarNavigationHost(
            coordinator: homeCoordinator,
            storeCoordinator: coordinator,
            handlesExternalNavigation: true,
            bottomStatusBarIsPresented: rootBottomStatusBarIsPresented
        ) {
            if case let .ready(_, contentLevel, _) = coordinator.state {
                bottomStatusBar(contentLevel: contentLevel)
            }
        }
        .calendarStoreEnvironment(state: coordinator.state)
    }

    private var rootBottomStatusBarIsPresented: Bool {
        guard case let .ready(_, contentLevel, _) = coordinator.state else { return false }
        return bottomStatusBarIsPresented(contentLevel: contentLevel)
    }

    private func bottomStatusBarIsPresented(contentLevel: ChineseCalendarSeedStoreContentLevel) -> Bool {
        coordinator.fullStoreDownloadProgress != nil || coordinator.canDownloadFullStore(contentLevel: contentLevel)
    }

    @ViewBuilder
    private func bottomStatusBar(contentLevel: ChineseCalendarSeedStoreContentLevel) -> some View {
        if let progress = coordinator.fullStoreDownloadProgress {
            CalendarDownloadProgressAccessory(progress: progress)
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
