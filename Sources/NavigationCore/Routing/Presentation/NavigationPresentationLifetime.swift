/// 只通知与本次请求直接配对的宿主；不保存业务资源或完成闭包。
@MainActor
protocol NavigationPresentationLifetimeObserver: AnyObject {
    func presentationLifetimeDidFinish(_ lifetime: NavigationPresentationLifetime)
}

/// 一次呈现从提交到结束的内部身份。节点和操作凭据共享它，不通过路由查找业务资源。
@MainActor
final class NavigationPresentationLifetime {
    weak var observer: (any NavigationPresentationLifetimeObserver)?
    private(set) var hostClaimed = false
    private(set) var finished = false
    private var finishRequested = false
    private var detachedPages: [NavigationPresentationLifetime] = []
    private var detachedAlert: NavigationPresentationLifetime?
    private weak var detachedParent: NavigationPresentationLifetime?

    /// Router 释放时保留请求之间的完成依赖，不保留节点、业务资源或宿主。
    /// 祖先实际关闭包含子页面的物理关闭，但不能代替后代 alert 的异步动作完成。
    func preserveDetachedChildren(
        pages: [NavigationPresentationLifetime], alert: NavigationPresentationLifetime?
    ) {
        detachedPages = pages.filter { !$0.finished }
        detachedAlert = alert?.finished == false ? alert : nil
        for child in detachedPages {
            child.detachedParent = self
        }
        detachedAlert?.detachedParent = self
    }

    /// 宿主接手展示后，即使页面尚未触发 onAppear，也必须等待真实关闭完成。
    func claimHost() {
        guard !finished else { return }
        hostClaimed = true
    }

    /// Router 先完成结构变更和排队操作，再发送一次结束通知。
    func finish() {
        guard !finished else { return }
        finishRequested = true
        for child in detachedPages {
            child.finish()
        }
        finishIfReady()
    }

    private func finishIfReady() {
        guard finishRequested, !finished,
              detachedPages.allSatisfy(\.finished), detachedAlert?.finished != false else { return }
        finished = true
        let parent = detachedParent
        detachedParent = nil
        detachedPages.removeAll()
        detachedAlert = nil
        let recipient = observer
        observer = nil
        recipient?.presentationLifetimeDidFinish(self)
        parent?.finishIfReady()
    }
}
