// swiftformat:disable modifierOrder

/// 导航命令未被接受的原因；调用方可以据此决策，不需要解析日志文字。
nonisolated public enum NavigationRejectionReason: String, Equatable, Sendable {
    case inactiveContext
    case undeclaredStack
    case incompatibleContainer
    case missingRootDestination
    case awaitingConfirmation
    case awaitingDismissal
    case alertInProgress
    case presentationAlreadyExists
    case sourceStackNotSelected

    /// 配置错误值得保留排查；正常的生命周期或事务阻挡只记录开发细节。
    var isConfigurationIssue: Bool {
        switch self {
        case .undeclaredStack, .incompatibleContainer, .missingRootDestination: true
        default: false
        }
    }
}
