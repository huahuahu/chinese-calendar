import SwiftUI

public extension View {
    /// 供通用模态容器调用 SwiftUI 的 fullScreenCover，item 有值时展示，变为 nil 时关闭。
    ///
    /// 这个方法只连接系统展示 API；模态数据和离开确认由上层框架管理。
    /// 业务页面使用呈现 Context 的 present(_:style:) 打开模态。
    /// onDismiss 在实际关闭完成后触发，不能用 item 变为 nil 的时机代替。
    func navigationFullScreenCover<Item: Identifiable>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> some View
    ) -> some View {
        fullScreenCover(item: item, onDismiss: onDismiss, content: content)
    }
}
