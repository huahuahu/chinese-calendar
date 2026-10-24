import ChineseCalendarLocalization
import SFSafeSymbols
import SwiftUI

/// 在主标签页的底部附件中提示用户下载完整日期数据。
struct FullStoreDownloadBanner: View {
    let action: () -> Void

    var body: some View {
        HStack(spacing: Constants.spacing) {
            Label(CalendarStringKey.Store.Download.Banner.title, systemSymbol: .arrowDownCircle)
                .font(.callout)

            Spacer(minLength: Constants.spacing)

            Button(CalendarStringKey.Store.Download.Banner.action, systemSymbol: .arrowDown, action: action)
                .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.vertical, Constants.verticalPadding)
        .background(.calendarSystemBackground)
    }

    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let spacing: CGFloat = 12
        static let verticalPadding: CGFloat = 10
    }
}

#Preview("下载提示", traits: .sizeThatFitsLayout) {
    FullStoreDownloadBanner(action: {})
}

#Preview("下载提示 · 深色", traits: .sizeThatFitsLayout) {
    FullStoreDownloadBanner(action: {})
        .preferredColorScheme(.dark)
}

#Preview("下载提示 · 最大辅助字号", traits: .sizeThatFitsLayout) {
    FullStoreDownloadBanner(action: {})
        .dynamicTypeSize(.accessibility5)
}
