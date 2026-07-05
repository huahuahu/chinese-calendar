import SwiftUI

struct DynastySummaryChip: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.caption)
            .bold()
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(.background, in: Capsule())
    }
}
