import SwiftUI

/// 由一个物理呈现宿主持有；记录仅对应本层尚未结束的请求，不提供业务对象查找接口。
@MainActor
final class NavigationPresentationEndpoint<
    Scope: NavigationScope, Destination: NavigationDestination, AlertRoute: NavigationAlertRoute
> {
    typealias Configuration = any NavigationHostConfiguration<Scope, Destination, AlertRoute>
    typealias Record = NavigationPresentationRenderRecord<Scope, Destination, AlertRoute>

    private weak var layer: NavigationLayer<Scope, Destination, AlertRoute>?
    private var configuration: Configuration?
    private var records: [Record] = []
    private var isDetached = false

    func attach(
        context: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        configuration: Configuration?
    ) {
        guard !isDetached, let layer = context.layer else { return }
        self.layer = layer
        self.configuration = configuration
        layer.presentationEndpoint = self
    }

    func submit(
        _ request: NavigationPresentationRequest<Scope, Destination, AlertRoute>,
        from context: NavigationPresentationContext<Scope, Destination, AlertRoute>,
        configuration: Configuration?, onFinish: @escaping @MainActor () -> Void
    ) -> NavigationPresentationSubmission {
        guard !isDetached, let router = context.router,
              let configuration = configuration ?? self.configuration
        else {
            return NavigationPresentationSubmission(result: .rejected(.hostUnavailable))
        }
        let lifetime = NavigationPresentationLifetime()
        let record = Record(lifetime: lifetime, configuration: configuration, onFinish: onFinish, endpoint: self)
        record.cancelRequest = { [weak router] in _ = router?.dismiss(lifetime: lifetime) }
        switch request {
        case .sheet, .fullScreen:
            record.modalMount = NavigationModalMount {
                context.presentationDidDismiss(lifetime: lifetime)
            }
        case .alert: break
        }
        // 先建立一次性配对，再交给 Router；同回合取消也能收到完成通知。
        records.append(record)
        let result = context.present(request, lifetime: lifetime)
        guard result.isAccepted else {
            record.discard()
            return NavigationPresentationSubmission(result: result)
        }
        return NavigationPresentationSubmission(
            result: result, handle: NavigationPresentationHandle(router: router, lifetime: lifetime)
        )
    }

    func record(for lifetime: NavigationPresentationLifetime) -> Record? {
        records.first { $0.lifetime === lifetime }
    }

    func remove(_ record: Record) {
        records.removeAll { $0 === record }
    }

    /// 真实宿主拆除时停止接受请求；已交给系统的请求由物理关闭完成收尾。
    func detach() {
        guard !isDetached else { return }
        isDetached = true
        if layer?.presentationEndpoint === self { layer?.presentationEndpoint = nil }
        let pending = records
        for record in pending {
            record.tearDown()
        }
        configuration = nil
    }
}
