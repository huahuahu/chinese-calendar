import SFSafeSymbols
import SwiftUI

/// 为 Label 补充同时接收 LocalizedStringResource 和 SFSymbol 的初始化方法。
/// 直接用 Text 构建标题，保留资源指定的 bundle，并让 SwiftUI 在显示时完成本地化。
extension Label where Title == Text, Icon == Image {
    init(_ title: LocalizedStringResource, systemSymbol: SFSymbol) {
        self.init {
            Text(title)
        } icon: {
            Image(systemSymbol: systemSymbol)
        }
    }
}

extension Button where Label == SwiftUI.Label<Text, Image> {
    init(_ title: LocalizedStringResource, systemSymbol: SFSymbol, action: @escaping () -> Void) {
        self.init(action: action) {
            SwiftUI.Label(title, systemSymbol: systemSymbol)
        }
    }
}
