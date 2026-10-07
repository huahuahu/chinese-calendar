import SFSafeSymbols
import SwiftUI

/// SFSafeSymbols 的文字重载尚未接收资源；保留 Text 的延迟本地化与 bundle 信息。
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
