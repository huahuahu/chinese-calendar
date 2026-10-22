import ChineseCalendarLogging

enum NavigationCoreLog {
    static let logger = ChineseCalendarLog.logger(category: "navigation")

    /// 仅在命令做出最终决策时调用；转发入口和状态查询不重复记录。
    @discardableResult
    static func record(
        _ result: NavigationMutationResult,
        operation: String,
        layer: NavigationLayerID? = nil,
        stack: String? = nil
    ) -> NavigationMutationResult {
        switch result {
        case .applied:
            write(operation: operation, outcome: "applied", layer: layer, stack: stack)
        case let .noChange(reason):
            write(operation: operation, outcome: "noChange", reason: reason.rawValue, layer: layer, stack: stack)
        case let .rejected(reason):
            rejected(reason, operation: operation, layer: layer, stack: stack)
        }
        return result
    }

    @discardableResult
    static func record(
        _ result: NavigationPresentationResult,
        operation: String,
        layer: NavigationLayerID? = nil,
        stack: String? = nil
    ) -> NavigationPresentationResult {
        switch result {
        case .applied:
            write(operation: operation, outcome: "applied", layer: layer, stack: stack)
        case .queued:
            write(operation: operation, outcome: "queued", layer: layer, stack: stack)
        case let .noChange(reason):
            write(operation: operation, outcome: "noChange", reason: reason.rawValue, layer: layer, stack: stack)
        case let .rejected(reason):
            rejected(reason, operation: operation, layer: layer, stack: stack)
        }
        return result
    }

    @discardableResult
    static func record(
        _ result: NavigationRequestResult,
        operation: String,
        layer: NavigationLayerID? = nil,
        stack: String? = nil
    ) -> NavigationRequestResult {
        switch result {
        case let .rejected(reason):
            rejected(reason, operation: operation, layer: layer, stack: stack)
        case let .noChange(reason):
            write(operation: operation, outcome: "noChange", reason: reason.rawValue, layer: layer, stack: stack)
        case .applied:
            write(operation: operation, outcome: "applied", layer: layer, stack: stack)
        case .awaitingConfirmation:
            write(operation: operation, outcome: "awaitingConfirmation", layer: layer, stack: stack)
        case .deferredUntilPresentationDismisses:
            write(operation: operation, outcome: "deferredUntilPresentationDismisses", layer: layer, stack: stack)
        case .deferredUntilAlertDismisses:
            write(operation: operation, outcome: "deferredUntilAlertDismisses", layer: layer, stack: stack)
        }
        return result
    }

    private static func rejected(
        _ reason: NavigationRejectionReason, operation: String, layer: NavigationLayerID?, stack: String?
    ) {
        write(
            operation: operation, outcome: "rejected", reason: reason.rawValue,
            layer: layer, stack: stack, isConfigurationIssue: reason.isConfigurationIssue
        )
    }

    private static func write(
        operation: String, outcome: String, reason: String = "none",
        layer: NavigationLayerID?, stack: String?, isConfigurationIssue: Bool = false
    ) {
        let layerID = layer.map { String(describing: $0) } ?? "none"
        let stackID = stack ?? "none"
        if isConfigurationIssue {
            logger.notice(
                """
                operation=\(operation, privacy: .public) outcome=\(outcome, privacy: .public) \
                reason=\(reason, privacy: .public) layer=\(layerID, privacy: .private) stack=\(
                    stackID,
                    privacy: .private
                )
                """
            )
        } else {
            logger.debug(
                """
                operation=\(operation, privacy: .public) outcome=\(outcome, privacy: .public) \
                reason=\(reason, privacy: .public) layer=\(layerID, privacy: .private) stack=\(
                    stackID,
                    privacy: .private
                )
                """
            )
        }
    }
}
