import SwiftUI

/// 显示在选中日详情卡片中，用于呈现一项日期属性。
struct CalendarFactTile: View {
    let title: LocalizedStringResource
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }
}

#Preview("不同长度的日期属性") {
    NavigationStack {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140))],
                spacing: 10
            ) {
                CalendarFactTile(title: "农历表达", value: "丙午年闰二月十五")
                CalendarFactTile(title: "日干支", value: "戊寅")
                CalendarFactTile(title: "对应日期", value: "2026年1月22日")
                CalendarFactTile(title: "对应日期缺失", value: "-")
                CalendarFactTile(
                    title: "较长内容",
                    value: "用于检查多行文字在窄屏和较大字号下的布局表现"
                )
            }
            .padding()
        }
        .navigationTitle("日期属性")
    }
}
