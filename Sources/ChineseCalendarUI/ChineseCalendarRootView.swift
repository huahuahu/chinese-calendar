import ChineseCalendarPersistence
import SwiftData
import SwiftUI

@MainActor
public struct ChineseCalendarRootView: View {
    @Environment(\.openWindow) private var openWindow
    @State private var coordinator: ChineseCalendarStoreCoordinator
    @State private var isSettingsPresented = false

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
                CalendarHomeView()
                    .environment(\.calendarStoreContentLevel, contentLevel)
                    .modelContainer(container)
                    .id(coordinator.storeIdentity(contentLevel: contentLevel, identityToken: identityToken))
                    .safeAreaInset(edge: .bottom) {
                        bottomStatusBar(contentLevel: contentLevel)
                    }
            case let .failed(message):
                CalendarStoreFailureView(message: message, retry: coordinator.prepareStore)
            }
        }
        .toolbar {
            #if os(iOS)
                ToolbarItem(placement: .topBarTrailing) {
                    Button("设置", systemImage: "gearshape") {
                        isSettingsPresented = true
                    }
                }
            #endif
        }
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                CalendarSettingsView(coordinator: coordinator)
            }
        }
        .task {
            await coordinator.prepareStoreIfNeeded()
        }
        .alert("完整数据下载失败", isPresented: downloadErrorIsPresented) {
            Button("好", role: .cancel) {}
        } message: {
            Text(coordinator.downloadErrorMessage ?? "请稍后再试。")
        }
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
            #if os(iOS)
                FullStoreDownloadBottomProgressView(progress: progress)
            #else
                FullStoreDownloadMacStatusBar(progress: progress, openProgressWindow: openDownloadProgressWindow)
            #endif
        } else if coordinator.canDownloadFullStore(contentLevel: contentLevel) {
            FullStoreDownloadBanner(action: startFullStoreDownload)
        }
    }

    private func startFullStoreDownload() {
        if coordinator.startFullStoreDownload() {
            openDownloadProgressWindow()
        }
    }

    private func openDownloadProgressWindow() {
        #if os(macOS)
            openWindow(id: FullStoreDownloadProgressWindow.sceneID)
        #endif
    }
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
