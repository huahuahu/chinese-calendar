@testable import ChineseCalendarUI
import NavigationCore
import SwiftUI
import Testing
import UIKit

/// App 集成测试使用真实窗口和公共导航入口，不手动调用 Core 的生命周期方法。
@MainActor
final class NavigationTestHost {
    typealias Router = NavigationRouter<CalendarTab, CalendarDestination, CalendarAlert>

    private let windowLease: NavigationTestWindowLease
    var window: UIWindow {
        windowLease.window
    }

    private(set) var contexts: [CalendarDestination: CalendarPresentationContext] = [:]
    private var appeared = false

    private init(windowLease: NavigationTestWindowLease) {
        self.windowLease = windowLease
    }

    static func show(_ content: some View) async throws -> NavigationTestHost {
        let windowLease = try await NavigationTestWindowLease.acquire()
        let host = NavigationTestHost(windowLease: windowLease)
        try await host.mount(content)
        return host
    }

    /// 仅用轻量页面记录环境 Context；真正的 sheet/fullScreen 仍由统一导航宿主展示。
    static func show(router: Router) async throws -> NavigationTestHost {
        let windowLease = try await NavigationTestWindowLease.acquire()
        let host = NavigationTestHost(windowLease: windowLease)
        let configuration = NavigationTestConfiguration { [weak host] destination, context in
            host?.contexts[destination] = context
        }
        try await host.mount(Color.clear.navigationHost(
            context: router.rootPresentation, configuration: configuration
        ))
        return host
    }

    /// 保留真实业务 builder 的内容与依赖，只追加环境 Context 的观测探针。
    func recording(
        configuration: some NavigationHostConfiguration<CalendarTab, CalendarDestination, CalendarAlert>
    ) -> some NavigationHostConfiguration<CalendarTab, CalendarDestination, CalendarAlert> {
        NavigationRecordingConfiguration(configuration: configuration) { [weak self] destination, context in
            self?.contexts[destination] = context
        }
    }

    func context(
        for destination: CalendarDestination, differentFrom previous: CalendarPresentationContext? = nil
    ) async throws -> CalendarPresentationContext {
        try await waitUntil {
            guard let context = self.contexts[destination] else { return false }
            return context !== previous
        }
        guard let context = contexts[destination] else { throw Failure.presentationMissing }
        return context
    }

    func presentedViewController() -> UIViewController? {
        guard let root = window.rootViewController else { return nil }
        return presentedController(in: root)
    }

    func waitForPresentation() async throws -> UIViewController {
        try await waitUntil {
            guard let controller = self.presentedViewController() else { return false }
            return controller.viewIfLoaded?.window != nil && !controller.isBeingPresented
        }
        guard let controller = presentedViewController() else { throw Failure.presentationMissing }
        return controller
    }

    func waitForAlert() async throws -> UIAlertController {
        try await waitUntil {
            guard let controller = self.presentedViewController() as? UIAlertController else { return false }
            return controller.viewIfLoaded?.window != nil && !controller.isBeingPresented
        }
        guard let alert = presentedViewController() as? UIAlertController else { throw Failure.presentationMissing }
        return alert
    }

    /// UIKit 的真实 completion 是物理关闭证据，调用方仍可继续等业务 onFinish。
    func dismissPresentedViewController(animated: Bool = true) async {
        guard let controller = presentedViewController() else { return }
        await dismiss(controller, animated: animated)
    }

    func close() async {
        defer { removeFromWindow() }
        if let root = window.rootViewController, presentedViewController() != nil {
            await dismiss(root, animated: false)
        }
    }

    private func dismiss(_ controller: UIViewController, animated: Bool) async {
        var completed = false
        controller.dismiss(animated: animated) { completed = true }
        do {
            try await waitUntil { completed }
        } catch {
            Issue.record(error, "测试宿主没有收到 UIKit 的关闭完成通知")
        }
    }

    /// 测试失败时的窗口清理；正常结束测试应先 await close()。
    func removeFromWindow() {
        contexts.removeAll()
        windowLease.release()
    }

    func waitUntil(
        timeout: Duration = .seconds(5), _ condition: @MainActor () -> Bool
    ) async throws {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: timeout)
        while !condition() {
            guard clock.now < deadline else { throw Failure.timedOut }
            // 轮询可观察到的真实条件；不把固定延时当作呈现或关闭完成。
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private func mount(_ content: some View) async throws {
        window.rootViewController = UIHostingController(rootView: content.onAppear { [weak self] in
            self?.appeared = true
        })
        window.makeKeyAndVisible()
        do {
            try await waitUntil {
                self.appeared && self.window.rootViewController?.viewIfLoaded?.window === self.window &&
                    self.window.windowScene?.activationState == .foregroundActive
            }
        } catch {
            removeFromWindow()
            throw error
        }
    }

    private func presentedController(in controller: UIViewController) -> UIViewController? {
        if let presented = controller.presentedViewController {
            return presentedController(in: presented) ?? presented
        }
        for child in controller.children {
            if let presented = presentedController(in: child) { return presented }
        }
        return nil
    }

    private enum Failure: Error {
        case timedOut
        case presentationMissing
    }
}

private struct NavigationTestConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = CalendarDestination
    typealias AlertRoute = CalendarAlert

    let record: @MainActor (CalendarDestination, CalendarPresentationContext) -> Void

    func destination(for destination: CalendarDestination) -> some View {
        NavigationTestPage(destination: destination, record: record)
    }

    func confirmationContent(
        for request: NavigationRequest<CalendarTab, CalendarDestination>
    ) -> NavigationConfirmationContent? {
        CalendarNavigationConfirmation.content(for: request)
    }

    func alert(for route: CalendarAlert, presentation: CalendarPresentationContext) -> NavigationAlertDefinition? {
        NavigationAlertDefinition(content: CalendarAlertContent.clearDataSucceeded) { _ in }
    }
}

private struct NavigationTestPage: View {
    let destination: CalendarDestination
    let record: @MainActor (CalendarDestination, CalendarPresentationContext) -> Void
    @Environment(CalendarPresentationContext.self) private var presentation

    var body: some View {
        Color.clear.onAppear { record(destination, presentation) }
    }
}

private struct NavigationRecordingConfiguration<
    Configuration: NavigationHostConfiguration<CalendarTab, CalendarDestination, CalendarAlert>
>: @MainActor NavigationHostConfiguration {
    typealias Scope = CalendarTab
    typealias Destination = CalendarDestination
    typealias AlertRoute = CalendarAlert

    let configuration: Configuration
    let record: @MainActor (CalendarDestination, CalendarPresentationContext) -> Void

    func destination(for destination: CalendarDestination) -> some View {
        configuration.destination(for: destination)
            .background(NavigationTestPage(destination: destination, record: record))
    }

    func confirmationContent(
        for request: NavigationRequest<CalendarTab, CalendarDestination>
    ) -> NavigationConfirmationContent? {
        configuration.confirmationContent(for: request)
    }

    func alert(for route: CalendarAlert, presentation: CalendarPresentationContext) -> NavigationAlertDefinition? {
        configuration.alert(for: route, presentation: presentation)
    }
}
