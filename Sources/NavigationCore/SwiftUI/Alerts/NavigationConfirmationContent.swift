import Foundation

/// 确认离开当前页面时使用的标题、说明和按钮文案，由业务根据导航请求提供。
///
/// 这里只保存文案。提示容器会给按钮绑定请求 ID，处理确认和取消。
/// LocalizedStringResource 会保留文案所属的资源表和 bundle，方便调用方使用自己的本地化资源。
public struct NavigationConfirmationContent {
    public let title: LocalizedStringResource
    public let message: LocalizedStringResource
    public let confirm: LocalizedStringResource
    public let cancel: LocalizedStringResource

    public init(
        title: LocalizedStringResource,
        message: LocalizedStringResource,
        confirm: LocalizedStringResource,
        cancel: LocalizedStringResource
    ) {
        self.title = title
        self.message = message
        self.confirm = confirm
        self.cancel = cancel
    }
}
