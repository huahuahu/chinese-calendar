import Foundation

/// 记录等待用户确认、等待模态关闭或等待 alert 结束的请求，以及延后执行的关闭操作。
/// 不保存正在展示的模态或 alert 会话；这些状态仍由 NavigationLayer 持有。
///
/// 三类等待分别保存：导航确认与模态关闭、alert 后的导航、alert 后的模态关闭。
/// 这里只决定请求是否可以继续，实际关闭和跳转由 Router 执行。
/// 下文的「已接受」表示无需再确认，可能是用户已批准，也可能是调用方未要求确认；不代表已经跳转。
struct NavigationCoordinationState<Scope: NavigationScope, Destination: NavigationDestination> {
    typealias Request = NavigationRequest<Scope, Destination>
    typealias Confirmation = NavigationConfirmation<Scope, Destination>

    /// Router 每次提交请求时，传入当前是否有业务 alert 或离开确认提示。
    /// 仅用于决定这次请求等待什么，不在这里保存 alert 的展示和关闭状态。
    enum ActiveAlert {
        case none
        /// 导航库为离开当前页面而显示的确认提示。
        case navigationConfirmation
        /// App 提交的业务提示，即使业务文案是在询问用户是否确认，也属于此类。
        case business
    }

    /// alert 结束后重新提交的请求，保留原来的确认策略。
    /// alert 结束指提示实际关闭，并且业务按钮的异步动作也已完成。
    enum RequestAfterAlert {
        /// 不再要求确认，但仍需等待 alert 和必要的模态关闭。
        case accepted(Request)
        /// 届时再检查是否需要离开确认；若没有模态等阻挡，可以直接导航。
        case evaluateConfirmation(Request)

        var request: Request {
            switch self {
            case let .accepted(request), let .evaluateConfirmation(request): request
            }
        }

        /// 重新传给 Router.submit 的策略，不表示必定会展示确认提示。
        var confirmIfPresented: Bool {
            if case .evaluateConfirmation = self { return true }
            return false
        }
    }

    enum DismissalIntent {
        case none
        /// 同一个模态的多次关闭请求按 ID 去重。
        case presentations(Set<UUID>)
        /// 关闭全部模态，覆盖此前和此后加入的单个模态关闭请求。
        case all
    }

    private enum RequestState {
        case none
        case awaitingConfirmation(Confirmation)
        /// 已接受的 A 等待模态关闭时，新来的 B 仍可能需要用户确认。
        /// 取消 B 保留 A；关闭完成前批准 B 则用 B 替换 A；先关闭则执行 A，并继续保留 B 的确认。
        case awaitingPresentationDismissal(acceptedRequest: Request, pendingConfirmation: Confirmation?)
    }

    private var requestState: RequestState = .none
    private var requestAfterAlert: RequestAfterAlert?
    private var dismissalAfterAlert: DismissalIntent = .none

    var acceptedRequestWaitingForDismissal: Request? {
        guard case let .awaitingPresentationDismissal(request, _) = requestState else { return nil }
        return request
    }

    var pendingConfirmation: Confirmation? {
        switch requestState {
        case .none: nil
        case let .awaitingConfirmation(confirmation): confirmation
        case let .awaitingPresentationDismissal(_, confirmation): confirmation
        }
    }

    var requestWaitingForAlert: Request? {
        requestAfterAlert?.request
    }

    /// 返回需要 Router 执行的下一步；状态本身不关闭模态或改写导航路径。
    /// hasPresentation 也包括已开始关闭、但尚未收到真实关闭完成回调的模态。
    mutating func submit(
        _ request: Request,
        confirmIfPresented: Bool,
        activeAlert: ActiveAlert,
        hasPresentation: Bool
    ) -> NavigationRequestResult {
        // 业务提示先完成，期间只保留最新请求及其策略；无需确认的请求也不能越过活动提示。
        if activeAlert == .business || (activeAlert != .none && !confirmIfPresented) {
            requestAfterAlert = confirmIfPresented ? .evaluateConfirmation(request) : .accepted(request)
            return .deferredUntilAlertDismisses
        }
        // 新请求可替换尚未批准的排队请求；新确认不能撤销已接受的请求。
        if !confirmIfPresented || requestAfterAlert?.confirmIfPresented == true {
            requestAfterAlert = nil
        }
        if confirmIfPresented, hasPresentation || pendingConfirmation != nil || activeAlert != .none {
            // 相同请求复用确认 ID；目标改变时创建新 ID，让旧提示的按钮无法批准新目标。
            if pendingConfirmation?.request != request {
                let confirmation = Confirmation(request: request)
                if let acceptedRequest = acceptedRequestWaitingForDismissal {
                    requestState = .awaitingPresentationDismissal(
                        acceptedRequest: acceptedRequest, pendingConfirmation: confirmation
                    )
                } else {
                    requestState = .awaitingConfirmation(confirmation)
                }
            }
            return .awaitingConfirmation
        }
        if hasPresentation {
            // 已无需确认，但必须等真实关闭完成；不能在这里提前修改导航路径。
            requestState = .awaitingPresentationDismissal(
                acceptedRequest: request, pendingConfirmation: pendingConfirmation
            )
            return .deferredUntilPresentationDismisses
        }
        return .applied
    }

    /// 取出并清除 ID 匹配的待确认请求，保留另一条已接受、正在等待关闭的请求。
    /// 确认和取消都调用此方法：Router 在确认时免确认地重新提交返回值，取消时丢弃它。
    /// 旧 ID 返回 nil 且不改变状态，避免迟到的按钮动作影响新请求。
    mutating func takeConfirmationRequest(id: UUID) -> Request? {
        guard let confirmation = pendingConfirmation, confirmation.id == id else { return nil }
        if let acceptedRequest = acceptedRequestWaitingForDismissal {
            requestState = .awaitingPresentationDismissal(
                acceptedRequest: acceptedRequest, pendingConfirmation: nil
            )
        } else {
            requestState = .none
        }
        return confirmation.request
    }

    /// Router 确认根界面打开的模态实际关闭后，才调用此方法取出已接受的请求。
    /// 取出即清除，重复完成回调不会再次执行同一请求；尚未批准的确认仍保留。
    mutating func takeAcceptedRequestAfterDismissal() -> Request? {
        let request = acceptedRequestWaitingForDismissal
        requestState = pendingConfirmation.map(RequestState.awaitingConfirmation) ?? .none
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
