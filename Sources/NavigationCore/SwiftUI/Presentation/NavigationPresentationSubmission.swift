/// present 的返回值：presentation request 是否被接受，以及用于取消或关闭本次 request 的 handle。
@MainActor
public struct NavigationPresentationSubmission {
    public let result: NavigationPresentationResult
    public let handle: NavigationPresentationHandle?

    init(result: NavigationPresentationResult, handle: NavigationPresentationHandle? = nil) {
        self.result = result
        self.handle = handle
    }
}
