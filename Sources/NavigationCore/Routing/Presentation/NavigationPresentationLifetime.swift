/// 一次请求的内部身份和关闭回调；不探测 UIKit 挂载，也不为取消或销毁补发通知。
@MainActor
final class NavigationPresentationLifetime {
    private enum State {
        case awaitingHost
        case claimed
        case finished
    }

    private var state: State = .awaitingHost
    private var onDismiss: (@MainActor () -> Void)?

    var hostClaimed: Bool {
        state == .claimed
    }

    var finished: Bool {
        state == .finished
    }

    init(onDismiss: (@MainActor () -> Void)? = nil) {
        self.onDismiss = onDismiss
    }

    /// SwiftUI 请求模态内容或 alert 宿主开始展示后，关闭需等待对应的系统回调。
    func claimHost() {
        guard state == .awaitingHost else { return }
        state = .claimed
    }

    func finish() {
        switch state {
        case .awaitingHost:
            state = .finished
            onDismiss = nil
        case .claimed:
            state = .finished
        case .finished:
            return
        }
    }

    /// 仅由系统关闭路径取走回调；先清空，避免重复通知和回调重入。
    func takeOnDismiss() -> (@MainActor () -> Void)? {
        defer { onDismiss = nil }
        return onDismiss
    }
}
