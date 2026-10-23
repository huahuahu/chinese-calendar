import SwiftUI

@MainActor
protocol NavigationAlertRenderLifetime: AnyObject {
    var tearDownPresentation: (() -> Void)? { get set }
}

/// 配置与闭包属于 View 侧的一次呈现；Router 仅通过 weak observer 通知其结束。
@MainActor
final class NavigationPresentationRenderRecord<
    Scope: NavigationScope, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
>: NavigationPresentationLifetimeObserver, NavigationAlertRenderLifetime {
    let lifetime: NavigationPresentationLifetime
    private(set) var configuration: (any NavigationHostConfiguration<Scope, Destination, AlertRoute>)?
    private var onFinish: (@MainActor () -> Void)?
    private weak var endpoint: NavigationPresentationEndpoint<Scope, Destination, AlertRoute>?
    private var teardownRequested = false
    var tearDownPresentation: (() -> Void)?
    var modalMount: NavigationModalMount?
    var cancelRequest: (() -> Void)?

    init(
        lifetime: NavigationPresentationLifetime,
        configuration: any NavigationHostConfiguration<Scope, Destination, AlertRoute>,
        onFinish: @escaping @MainActor () -> Void,
        endpoint: NavigationPresentationEndpoint<Scope, Destination, AlertRoute>
    ) {
        self.lifetime = lifetime
        self.configuration = configuration
        self.onFinish = onFinish
        self.endpoint = endpoint
        lifetime.observer = self
    }

    func presentationLifetimeDidFinish(_ lifetime: NavigationPresentationLifetime) {
        guard self.lifetime === lifetime else { return }
        let retainedConfiguration = configuration
        let completion = onFinish
        discard()
        completion?()
        withExtendedLifetime(retainedConfiguration) {}
    }

    func discard() {
        lifetime.observer = nil
        onFinish = nil
        configuration = nil
        tearDownPresentation = nil
        modalMount?.releaseResources()
        modalMount = nil
        cancelRequest = nil
        endpoint?.remove(self)
    }

    func tearDown() {
        // 旧请求可能仍在等待异步动作，重复切换宿主不能再次调用已经复用的 presenter。
        guard !teardownRequested else { return }
        teardownRequested = true
        cancelRequest?()
        guard !lifetime.finished else { return }
        if lifetime.hostClaimed {
            if let modalMount {
                modalMount.tearDown(keeping: self)
            } else {
                tearDownPresentation?()
            }
        } else {
            lifetime.finish()
        }
    }
}
