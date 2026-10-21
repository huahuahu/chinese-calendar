import Foundation

/// 记录等待用户确认、等待模态关闭或等待 alert 结束的请求，以及延后执行的关闭操作。
/// 不保存正在展示的模态或 alert 会话；这些状态仍由 NavigationLayer 持有。
struct NavigationCoordinationState<Scope: NavigationScope, Destination: NavigationDestination> {
    typealias Request = NavigationRequest<Scope, Destination>
    typealias Confirmation = NavigationConfirmation<Scope, Destination>

    /// Router 每次提交请求时，传入当前是否有业务 alert 或离开确认提示。
    /// 仅用于决定这次请求等待什么，不在这里保存 alert 的展示和关闭状态。
    enum AlertBarrier {
        case none, confirmation, business
    }

    enum RequestAfterAlert {
        case accepted(Request)
        case evaluateConfirmation(Request)

        var request: Request {
            switch self {
            case let .accepted(request), let .evaluateConfirmation(request): request
            }
        }

        var needsConfirmation: Bool {
            if case .evaluateConfirmation = self { return true }
            return false
        }
    }

    enum DismissalIntent {
        case none
        case presentations(Set<UUID>)
        case all
    }

    private enum RequestState {
        case none
        case awaitingConfirmation(Confirmation)
        /// 已接受 A 与待确认 B 可以并存；取消 B 不撤销 A。
        case awaitingDismissal(accepted: Request, nextConfirmation: Confirmation?)
    }

    private var requests: RequestState = .none
    private var requestAfterAlert: RequestAfterAlert?
    private var dismissalAfterAlert: DismissalIntent = .none

    var deferredRequest: Request? {
        guard case let .awaitingDismissal(request, _) = requests else { return nil }
        return request
    }

    var pendingConfirmation: Confirmation? {
        switch requests {
        case .none: nil
        case let .awaitingConfirmation(confirmation): confirmation
        case let .awaitingDismissal(_, confirmation): confirmation
        }
    }

    var requestWaitingForAlert: Request? {
        requestAfterAlert?.request
    }

    /// 返回需要 Router 执行的下一步；状态本身不关闭模态或改写导航路径。
    mutating func submit(
        _ request: Request,
        confirmIfPresented: Bool,
        alert: AlertBarrier,
        hasPresentation: Bool
    ) -> NavigationRequestResult {
        if alert == .business || (alert != .none && !confirmIfPresented) {
            requestAfterAlert = confirmIfPresented ? .evaluateConfirmation(request) : .accepted(request)
            return .deferredUntilAlertDismisses
        }
        // 新请求可替换尚未批准的排队请求；新确认不能撤销已接受的请求。
        if !confirmIfPresented || requestAfterAlert?.needsConfirmation == true {
            requestAfterAlert = nil
        }
        if confirmIfPresented, hasPresentation || pendingConfirmation != nil || alert != .none {
            if pendingConfirmation?.request != request {
                let confirmation = Confirmation(request: request)
                if let accepted = deferredRequest {
                    requests = .awaitingDismissal(accepted: accepted, nextConfirmation: confirmation)
                } else {
                    requests = .awaitingConfirmation(confirmation)
                }
            }
            return .awaitingConfirmation
        }
        if hasPresentation {
            requests = .awaitingDismissal(accepted: request, nextConfirmation: pendingConfirmation)
            return .deferredUntilPresentationDismisses
        }
        return .applied
    }

    /// 移除 ID 匹配的确认提示并返回其请求，保留另一条已批准、正在等待关闭的请求。
    /// 调用方根据用户选择，重新提交返回的请求或将其丢弃。
    mutating func resolveConfirmation(id: UUID) -> Request? {
        guard let confirmation = pendingConfirmation, confirmation.id == id else { return nil }
        if let accepted = deferredRequest {
            requests = .awaitingDismissal(accepted: accepted, nextConfirmation: nil)
        } else {
            requests = .none
        }
        return confirmation.request
    }

    /// 根界面打开的模态实际关闭后，取出并清除等待关闭的已接受请求；待确认请求继续保留。
    mutating func presentationDidDismiss() -> Request? {
        let request = deferredRequest
        requests = pendingConfirmation.map(RequestState.awaitingConfirmation) ?? .none
        return request
    }

    mutating func deferDismissalUntilAlertEnds(id: UUID) {
        switch dismissalAfterAlert {
        case .none:
            dismissalAfterAlert = .presentations([id])
        case var .presentations(ids):
            ids.insert(id)
            dismissalAfterAlert = .presentations(ids)
        case .all:
            break
        }
    }

    mutating func deferAllDismissalsUntilAlertEnds() {
        dismissalAfterAlert = .all
    }

    /// alert 关闭且按钮动作完成后，取出并清除延后的模态关闭操作。
    /// 如果曾请求关闭所有模态，结果为 all，无需再逐个处理指定 ID。
    mutating func takeDismissalAfterAlert() -> DismissalIntent {
        let intent = dismissalAfterAlert
        dismissalAfterAlert = .none
        return intent
    }

    /// 延后的关闭操作和排队呈现处理完后，取出并清除等待 alert 的导航请求及其确认要求。
    mutating func takeRequestAfterAlert() -> RequestAfterAlert? {
        let request = requestAfterAlert
        requestAfterAlert = nil
        return request
    }
}
