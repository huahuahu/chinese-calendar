@testable import ChineseCalendarUI
import NavigationCore
import Observation
import SwiftData
import SwiftUI
import Testing

@MainActor
@Suite("模态主标签页的实时下载附件", .serialized)
struct CalendarDownloadAccessoryTests {
    @Test(.timeLimit(.minutes(1)), arguments: [NavigationPresentationStyle.sheet, .fullScreen])
    func retainedModalConfigurationReevaluatesAccessoryVisibility(style: NavigationPresentationStyle) async throws {
        let coordinator = CalendarHomeCoordinator()
        let input = CalendarAccessoryInput()
        let recorder = CalendarAccessoryRecorder()
        let configuration = CalendarNavigationConfiguration(
            coordinator: coordinator, storeCoordinator: nil,
            bottomStatusBarIsPresented: { recorder.recordVisibility(input.isPresented) },
            bottomStatusBar: { CalendarAccessoryContent(label: input.label, recorder: recorder) }
        )
        // 根内容不读取输入，也不替换宿主；变化必须通过保留的配置更新真实模态页面。
        let host = try await NavigationTestHost.show(Color.clear
            .navigationHost(context: coordinator.router.navigation.rootPresentation, configuration: configuration)
            .environment(coordinator)
            .modelContainer(PreviewSampleData.makeModelContainer(includesSampleData: false)))
        defer { host.removeFromWindow() }
        var finishCount = 0
        let submission = coordinator.router.navigation.rootPresentation.present(
            .mainTabs, style: style, initialStack: .scope(.settings),
            rootDestinations: CalendarRouter.mainTabRoots, onFinish: { finishCount += 1 }
        )
        try #require(submission.result == .applied)
        let modal = try await host.waitForPresentation()
        try await host.waitUntil { recorder.visibility.last == false }

        input.isPresented = true
        try await host.waitUntil { recorder.visibility.last == true && recorder.label == input.label }
        input.label = "updated"
        try await host.waitUntil { recorder.label == "updated" }
        #expect(host.presentedViewController() === modal)

        input.isPresented = false
        try await host.waitUntil { recorder.visibility.last == false }
        #expect(host.presentedViewController() === modal)
        #expect(finishCount == 0)
        #expect(submission.handle?.dismiss().isAccepted == true)
        try await host.waitUntil { finishCount == 1 }
        await host.close()
    }
}

@MainActor
@Observable
private final class CalendarAccessoryInput {
    var isPresented = false
    var label = "initial"
}

@MainActor
private final class CalendarAccessoryRecorder {
    var visibility: [Bool] = []
    var label: String?

    func recordVisibility(_ isPresented: Bool) -> Bool {
        visibility.append(isPresented)
        return isPresented
    }
}

private struct CalendarAccessoryContent: View {
    let label: String
    let recorder: CalendarAccessoryRecorder

    var body: some View {
        Text(label)
            .onAppear { recorder.label = label }
            .onChange(of: label) { _, label in recorder.label = label }
    }
}
