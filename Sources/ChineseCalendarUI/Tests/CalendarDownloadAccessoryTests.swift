#if DEBUG
    @testable import ChineseCalendarUI
    import NavigationCore
    import SwiftUI
    import Testing
    import UIKit

    @MainActor
    @Suite("模态主标签页的下载附件显隐与呈现身份", .serialized)
    struct CalendarDownloadAccessoryTests {
        @Test(.timeLimit(.minutes(1)), arguments: [NavigationPresentationStyle.sheet, .fullScreen])
        func modalAccessoryVisibilityPreservesPresentation(style: NavigationPresentationStyle) async throws {
            let coordinator = CalendarHomeCoordinator()
            let clock = CalendarDownloadTestClock()
            let store = ChineseCalendarStoreCoordinator(
                fullStoreConfiguration: nil,
                fullStoreDownloadSimulator: FullStoreDownloadSimulator { _ in try await clock.wait() }
            )
            store.prepareStore()
            guard case .ready = store.state else {
                Issue.record("App 测试宿主未能准备日历数据")
                return
            }
            do {
                try await verifyAccessory(style: style, coordinator: coordinator, store: store, clock: clock)
            } catch {
                await store.cancelSimulatedFullStoreDownload()
                throw error
            }
        }

        private func verifyAccessory(
            style: NavigationPresentationStyle, coordinator: CalendarHomeCoordinator,
            store: ChineseCalendarStoreCoordinator, clock: CalendarDownloadTestClock
        ) async throws {
            let host = try await NavigationTestHost.show(Color.clear
                .calendarNavigationHost(coordinator: coordinator, storeCoordinator: store)
                .calendarStoreEnvironment(state: store.state))
            defer { host.removeFromWindow() }
            var finishCount = 0
            let submission = coordinator.router.navigation.rootPresentation.present(
                .mainTabs, style: style, initialStack: .scope(.settings),
                rootDestinations: CalendarRouter.mainTabRoots, onDismiss: { finishCount += 1 }
            )
            try #require(submission.result == .applied)
            let modal = try await diagnose("等待模态呈现", host: host) { try await host.waitForPresentation() }
            try await diagnose("寻找 Tab controller", host: host, modal: modal) {
                try await host.waitUntil { tabBarController(in: modal) != nil }
            }
            let tabs = try #require(tabBarController(in: modal))
            #expect(tabs.bottomAccessory == nil)

            try #require(store.startSimulatedFullStoreDownload())
            try await waitForAccessory(.preparingManifest, store: store, in: tabs, host: host)
            #expect(host.presentedViewController() === modal)
            // 第一次等待结束准备阶段，后续 25 次等待将模拟下载推进到 50%。
            clock.allowedWaits = 26
            try await waitForAccessory(.downloading(progress: 0.5), store: store, in: tabs, host: host)
            #expect(host.presentedViewController() === modal)

            await store.cancelSimulatedFullStoreDownload()
            try await diagnose("取消下载后隐藏附件", host: host, modal: modal) {
                try await host.waitUntil { tabs.bottomAccessory == nil }
            }
            #expect(host.presentedViewController() === modal)
            #expect(finishCount == 0)
            #expect(submission.handle?.dismiss().isAccepted == true)
            try await diagnose("等待原生关闭及一次回调", host: host, modal: modal) {
                try await host.waitUntil { finishCount == 1 && host.presentedViewController() == nil }
            }
            await host.close()
            #expect(finishCount == 1)
        }

        private func waitForAccessory(
            _ progress: FullStoreDownloadProgress, store: ChineseCalendarStoreCoordinator,
            in tabs: UITabBarController, host: NavigationTestHost
        ) async throws {
            // store 进度只用于确定测试阶段；此处验证原生附件仍可见，不验证文字，文字更新需要设备交互证据。
            try await diagnose("等待进度阶段及可见附件 \(progress)", host: host, modal: tabs) {
                try await host.waitUntil {
                    guard store.fullStoreDownloadProgress == progress,
                          let content = tabs.bottomAccessory?.contentView
                    else { return false }
                    return content.window != nil && !content.isHidden
                }
            }
        }

        private func diagnose<Value>(
            _ stage: String, host: NavigationTestHost, modal: UIViewController? = nil,
            operation: () async throws -> Value
        ) async throws -> Value {
            do {
                return try await operation()
            } catch {
                let controller = modal ?? host.presentedViewController()
                let tabs = controller.flatMap { tabBarController(in: $0) }
                let content = tabs?.bottomAccessory?.contentView
                Issue.record(error, """
                附件测试阶段：\(stage)
                presentedController=\(String(describing: host.presentedViewController()))
                tabControllerFound=\(tabs != nil), tabWindow=\(tabs?.viewIfLoaded?.window != nil)
                bottomAccessoryExists=\(tabs?.bottomAccessory != nil), contentWindow=\(content?.window != nil)
                contentHidden=\(String(describing: content?.isHidden))
                contentFrame=\(String(describing: content?.frame))
                """)
                throw error
            }
        }

        private func tabBarController(in controller: UIViewController) -> UITabBarController? {
            if let tabs = controller as? UITabBarController { return tabs }
            return controller.children.lazy.compactMap { tabBarController(in: $0) }.first
        }
    }

    @MainActor
    private final class CalendarDownloadTestClock {
        var allowedWaits = 0
        private var requestedWaits = 0

        func wait() async throws {
            requestedWaits += 1
            while requestedWaits > allowedWaits {
                try await Task.sleep(for: .milliseconds(10))
            }
        }
    }
#endif
