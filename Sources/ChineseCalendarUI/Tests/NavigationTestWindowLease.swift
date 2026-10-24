import UIKit

/// 跨 Suite 和两类宿主串行使用真实 scene，避免测试窗口争夺 keyWindow。
@MainActor
final class NavigationTestWindowLease {
    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Void, any Error>
    }

    private static var occupied = false
    private static var waiters: [Waiter] = []

    let window: UIWindow
    private weak var previousKeyWindow: UIWindow?
    private var released = false

    private init(scene: UIWindowScene) {
        previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
    }

    static func acquire() async throws -> NavigationTestWindowLease {
        try await acquireTurn()
        do {
            try Task.checkCancellation()
            let scene = try await foregroundScene()
            return NavigationTestWindowLease(scene: scene)
        } catch {
            releaseTurn()
            throw error
        }
    }

    func release() {
        guard !released else { return }
        released = true
        window.isHidden = true
        window.rootViewController = nil
        window.windowScene = nil
        previousKeyWindow?.makeKey()
        Self.releaseTurn()
    }

    private static func acquireTurn() async throws {
        try Task.checkCancellation()
        guard occupied else {
            occupied = true
            return
        }
        let id = UUID()
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                if Task.isCancelled {
                    continuation.resume(throwing: CancellationError())
                } else {
                    waiters.append(Waiter(id: id, continuation: continuation))
                }
            }
        } onCancel: {
            Task { @MainActor in
                guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
                waiters.remove(at: index).continuation.resume(throwing: CancellationError())
            }
        }
    }

    private static func releaseTurn() {
        if waiters.isEmpty {
            occupied = false
        } else {
            waiters.removeFirst().continuation.resume()
        }
    }

    private static func foregroundScene() async throws -> UIWindowScene {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(8))
        while true {
            try Task.checkCancellation()
            let windowScenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            if let scene = windowScenes.first(where: { $0.activationState == .foregroundActive }) {
                return scene
            }
            guard clock.now < deadline else {
                let scenes = UIApplication.shared.connectedScenes.map {
                    "\(type(of: $0)) state=\($0.activationState)"
                }.sorted()
                throw Failure.noForegroundWindowScene(scenes)
            }
            // 只等待真实 scene 进入前台，不以固定延时推断其已经就绪。
            try await Task.sleep(for: .milliseconds(10))
        }
    }

    private enum Failure: Error, CustomStringConvertible {
        case noForegroundWindowScene([String])

        nonisolated var description: String {
            switch self {
            case let .noForegroundWindowScene(scenes):
                "测试宿主没有前台 UIWindowScene；请运行 App-hosted 测试。connectedScenes=\(scenes)"
            }
        }
    }
}
