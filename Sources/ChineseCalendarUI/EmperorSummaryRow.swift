import ChineseCalendarPersistence
import SwiftUI

struct EmperorSummaryRow: View {
    let emperor: Emperor

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(emperor.displayName)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var subtitle: String {
        let names = [
            emperor.personalName,
            emperor.templeName,
            emperor.posthumousName
        ]
        .compactMap(\.self)

        let nameText = names.isEmpty ? "未记录别名" : names.joined(separator: " · ")
        return "\(nameText) · \(emperor.reignSegments.count) 段在位 · \(emperor.reignEras.count) 个年号"
    }
}
