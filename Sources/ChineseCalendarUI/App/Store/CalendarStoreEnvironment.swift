import ChineseCalendarPersistence
import SwiftData
import SwiftUI

private struct CalendarStoreContentLevelKey: EnvironmentKey {
    static let defaultValue = ChineseCalendarSeedStoreContentLevel.base
}

extension EnvironmentValues {
    var calendarStoreContentLevel: ChineseCalendarSeedStoreContentLevel {
        get { self[CalendarStoreContentLevelKey.self] }
        set { self[CalendarStoreContentLevelKey.self] = newValue }
    }
}

extension View {
    /// 页面按容器实例重建并保活该实例，根与递归模态均使用同一个边界。
    @ViewBuilder
    func calendarStoreContent(state: CalendarStoreBootstrapState?) -> some View {
        if case let .ready(container, contentLevel, _) = state {
            CalendarStoreContent(container: container, contentLevel: contentLevel, content: self)
                .id(ObjectIdentifier(container))
        } else {
            self
        }
    }

    /// 为导航树提供就绪数据库的 ModelContext 和数据完整度。
    /// 通过修改 Environment 更新数据，不按存储状态创建不同的 View 分支，以保留导航宿主的生命周期。
    func calendarStoreEnvironment(state: CalendarStoreBootstrapState) -> some View {
        transformEnvironment(\.self) { environment in
            if case let .ready(container, contentLevel, _) = state {
                environment.modelContext = container.mainContext
                environment.calendarStoreContentLevel = contentLevel
            }
        }
    }
}

private struct CalendarStoreContent<Content: View>: View {
    @State private var lifetime: CalendarStoreContentLifetime
    let contentLevel: ChineseCalendarSeedStoreContentLevel
    let content: Content

    init(container: ModelContainer, contentLevel: ChineseCalendarSeedStoreContentLevel, content: Content) {
        _lifetime = State(initialValue: CalendarStoreContentLifetime(container: container))
        self.contentLevel = contentLevel
        self.content = content
    }

    var body: some View {
        if let container = lifetime.container {
            content
                .modelContainer(container)
                .environment(\.calendarStoreContentLevel, contentLevel)
        }
    }
}

/// State 的生命周期覆盖仍可能更新的旧页面；释放后再尝试回收其退役文件。
private final class CalendarStoreContentLifetime {
    private(set) var container: ModelContainer?
    private let storeURL: URL?

    init(container: ModelContainer) {
        self.container = container
        storeURL = container.configurations.first?.url
    }

    deinit {
        container = nil
        if let storeURL { ChineseCalendarModelContainerFactory.collectRetiredSeedStores(for: storeURL) }
    }
}

#Preview("完整日期数据内容") {
    let result = Result { try PreviewSampleData.makeModelContainer() }

    switch result {
    case let .success(container):
        NavigationStack {
            EmperorDetailView(emperorID: HistoryPreviewData.emperorID)
        }
        .calendarStoreContent(state: .ready(
            container: container,
            contentLevel: .full,
            identityToken: "preview-full-store-content"
        ))
    case let .failure(error):
        Text(verbatim: error.localizedDescription)
    }
}
