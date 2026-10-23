import NavigationCore
import SwiftUI

/// 普通 import 的调用方只使用配置、命令、绑定、结果和不透明凭据。
@MainActor
func supportedPublicUsage() -> some View {
    let router = APIRouter(rootDestination: .home)
    let presentation = router.rootPresentation
    @Bindable var stack = presentation.context(for: .primary)
    @Bindable var layer = presentation
    let pathBinding: Binding<[APIDestination]> = $stack.path
    let stackBinding: Binding<NavigationStackID<APIScope>> = $layer.selectedStack
    _ = pathBinding
    _ = stackBinding
    _ = stack.rootDestination
    _ = stack.id
    _ = stack.push(.detail)
    _ = stack.pop()
    _ = stack.setPath([])
    _ = stack.setRootDestination(.home)
    _ = presentation.scoped(to: .primary).unscoped()
    _ = presentation.isPresented
    let submission = presentation.present(.sheet(.detail), configuration: APIConfiguration(), onFinish: {})
    let result: NavigationPresentationResult = submission.result
    let handle: NavigationPresentationHandle? = submission.handle
    _ = result.isAccepted
    _ = handle?.dismiss()
    _ = presentation.present(.detail, style: .fullScreen, onFinish: {})
    _ = presentation.presentAlert(.notice, onFinish: {})
    _ = presentation.dismiss()
    _ = router.submit(.push(.detail, on: .primary))
    _ = router.dismissAllPresentations()
    _ = router.presentAlert(.notice, onFinish: {})
    return NavigationRootView(context: presentation)
        .navigationHost(context: presentation, configuration: APIConfiguration())
}
