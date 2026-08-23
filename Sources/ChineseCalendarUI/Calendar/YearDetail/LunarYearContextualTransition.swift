import SwiftUI

/// 在 transition 执行时读取共享方向，使入场和离场内容属于同一次年份导航。
struct LunarYearContextualTransition: Transition {
    let context: LunarYearTransitionContext

    func body(content: Content, phase: TransitionPhase) -> some View {
        let edge: Edge = switch context.direction {
        case .earlier:
            .leading
        case .later:
            .trailing
        }

        PushTransition(edge: edge).apply(content: content, phase: phase)
    }
}
