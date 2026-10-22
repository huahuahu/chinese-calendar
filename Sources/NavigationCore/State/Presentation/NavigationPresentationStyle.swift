/// 指定模态使用 sheet 还是全屏方式展示，同一个路由数据可以选择不同的展示方式。
/// push 页面不使用这个枚举；是否给模态添加导航栈，由 Destination 的容器声明决定。
public enum NavigationPresentationStyle: String, Sendable {
    /// 使用 SwiftUI 的 sheet；高度、拖动指示器等外观由页面配置。
    case sheet
    /// 使用 SwiftUI 的 fullScreenCover 全屏展示。
    case fullScreen
}
