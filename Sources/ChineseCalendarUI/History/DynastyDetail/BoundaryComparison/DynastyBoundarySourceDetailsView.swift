import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

/// 由边界比较卡片弹出，用于展示朝代边界的原始来源说明。
struct DynastyBoundarySourceDetailsView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let sourceSpacing: CGFloat = 10
        static let disclosureTopPadding: CGFloat = 8
        static let detailSpacing: CGFloat = 3
    }

    let claimedStartDate: ChineseDateExpression
    let orthodoxStartDate: ChineseDateExpression?
    let claimedEndDate: ChineseDateExpression
    let orthodoxEndDate: ChineseDateExpression?
    let note: String?

    var body: some View {
        DisclosureGroup {
            sourceDetails
        } label: {
            Label("来源和精度", systemSymbol: .infoCircle)
                .font(.callout)
        }
    }

    private var sourceDetails: some View {
        VStack(alignment: .leading, spacing: Constants.sourceSpacing) {
            sourceDetailRow("自称开始", date: claimedStartDate)
            sourceDetailRow("正统开始", date: orthodoxStartDate)
            sourceDetailRow("自称结束", date: claimedEndDate)
            sourceDetailRow("正统结束", date: orthodoxEndDate)

            if let note {
                Text(note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, Constants.disclosureTopPadding)
    }

    private func sourceDetailRow(_ title: String, date: ChineseDateExpression?) -> some View {
        VStack(alignment: .leading, spacing: Constants.detailSpacing) {
            Text(title)
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)

            Text(detailText(for: date))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func detailText(for date: ChineseDateExpression?) -> String {
        guard let date else {
            return "不详"
        }

        var parts = [precisionText(for: date)]

        if let index = date.index {
            parts.append("index \(index)")
        }

        parts.append(date.sourceText)

        if let note = date.note {
            parts.append(note)
        }

        return parts.joined(separator: " · ")
    }

    private func precisionText(for date: ChineseDateExpression) -> String {
        switch date.precision {
        case .year:
            "年精度"
        case .month:
            "月精度"
        case .day:
            "日精度"
        case .range:
            "范围精度"
        case .unknown:
            "精度未知"
        }
    }
}

#Preview {
    let sample = HistoryPreviewData.makeSample()

    DynastyBoundarySourceDetailsView(
        claimedStartDate: sample.dynasty.claimedStartDate,
        orthodoxStartDate: sample.period.startBoundary?.date,
        claimedEndDate: sample.dynasty.claimedEndDate,
        orthodoxEndDate: sample.period.endBoundary?.date,
        note: sample.period.note
    )
    .padding()
}
