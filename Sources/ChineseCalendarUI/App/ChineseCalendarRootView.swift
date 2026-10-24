import ChineseCalendarLocalization
import ChineseCalendarPersistence
import NavigationCore
import SFSafeSymbols
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
            storeCoordinator: coordinator
        )
        .calendarStoreEnvironment(state: coordinator.state)
        .onOpenURL { url in
            guard let deepLink = CalendarDeepLinkParser.deepLink(from: url) else { return }
            homeCoordinator.openDeepLink(deepLink)
        }
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
