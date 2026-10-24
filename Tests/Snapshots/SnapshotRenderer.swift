import SwiftUI
import UIKit

/// 在真实前台 scene 中渲染，等待连续稳定帧后截图，保留系统材质和导航栏效果。
@MainActor
enum SnapshotRenderer {
    static func capture(_ content: some View, appearance: SnapshotAppearance) async throws -> UIImage {
        let scene = try await foregroundScene()
        let previousWindow = scene.windows.first(where: \.isKeyWindow)
        let window = SnapshotWindow(windowScene: scene, appearance: appearance)
        let hosting = UIHostingController(rootView: content
            .environment(\.locale, Locale(identifier: "zh_Hans_CN"))
            .environment(\.timeZone, TimeZone(identifier: "Asia/Shanghai") ?? .gmt)
            .environment(\.colorScheme, appearance.colorScheme)
            .environment(\.dynamicTypeSize, appearance.dynamicTypeSize)
            .transaction { $0.animation = nil; $0.disablesAnimations = true })
        window.rootViewController = hosting
        let animationsEnabled = UIView.areAnimationsEnabled
        UIView.setAnimationsEnabled(false)
        defer {
            window.isHidden = true
            window.rootViewController = nil
            window.windowScene = nil
            previousWindow?.makeKey()
            UIView.setAnimationsEnabled(animationsEnabled)
        }
        window.makeKeyAndVisible()
        return try await stableImage(in: hosting.view, size: appearance.size)
    }

    private static func stableImage(in view: UIView, size: CGSize) async throws -> UIImage {
        let deadline = ContinuousClock.now.advanced(by: .seconds(8))
        var previous: Data?
        var identicalFrames = 0
        while ContinuousClock.now < deadline {
            try Task.checkCancellation()
            view.setNeedsLayout()
            view.layoutIfNeeded()
            guard view.bounds.size == size else { throw Failure.unexpectedViewport(view.bounds.size) }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            var rendered = false
            let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
                rendered = view.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            }
            guard rendered else { throw Failure.incompleteHierarchy }
            let bytes = image.pngData()
            if let bytes, bytes == previous {
                identicalFrames += 1
                if identicalFrames >= 3 {
                    // 与磁盘基准使用同一 PNG 解码路径，消除渲染缓冲区与持久化图像的色彩精度差异。
                    guard let normalizedImage = UIImage(data: bytes, scale: 1) else { throw Failure.invalidImage }
                    return normalizedImage
                }
            } else {
                identicalFrames = 0
            }
            previous = bytes
            // 轮询实际帧一致性，而非以固定延时推断 SwiftUI 的首次任务和布局已完成。
            try await Task.sleep(for: .milliseconds(50))
        }
        throw Failure.unstableRendering
    }

    private static func foregroundScene() async throws -> UIWindowScene {
        let deadline = ContinuousClock.now.advanced(by: .seconds(8))
        while ContinuousClock.now < deadline {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            if let scene = scenes.first(where: { $0.activationState == .foregroundActive }) {
                return scene
            }
            try await Task.sleep(for: .milliseconds(20))
        }
        throw Failure.noForegroundScene
    }

    private enum Failure: Error {
        case noForegroundScene
        case unstableRendering
        case unexpectedViewport(CGSize)
        case invalidImage
        case incompleteHierarchy
    }
}

private final class SnapshotWindow: UIWindow {
    private let fixedSafeArea: UIEdgeInsets

    init(windowScene: UIWindowScene, appearance: SnapshotAppearance) {
        fixedSafeArea = appearance.safeArea
        super.init(windowScene: windowScene)
        frame = CGRect(origin: .zero, size: appearance.size)
        traitOverrides.userInterfaceIdiom = appearance == .tablet ? .pad : .phone
        traitOverrides.horizontalSizeClass = appearance == .tablet ? .regular : .compact
        traitOverrides.verticalSizeClass = .regular
        traitOverrides.userInterfaceStyle = appearance == .dark ? .dark : .light
        traitOverrides.preferredContentSizeCategory = appearance == .accessibility
            ? .accessibilityExtraExtraExtraLarge : .large
        traitOverrides.displayScale = 1
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("截图窗口只支持代码初始化")
    }

    override var safeAreaInsets: UIEdgeInsets {
        fixedSafeArea
    }
}
