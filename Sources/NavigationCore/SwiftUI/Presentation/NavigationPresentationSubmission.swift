/// 一次呈现的同步接收结果，以及只允许结束该请求的操作凭据。
@MainActor
public struct NavigationPresentationSubmission {
    public let result: NavigationPresentationResult
    public let handle: NavigationPresentationHandle?

    init(result: NavigationPresentationResult, handle: NavigationPresentationHandle? = nil) {
        self.result = result
        self.handle = handle
    }
}
