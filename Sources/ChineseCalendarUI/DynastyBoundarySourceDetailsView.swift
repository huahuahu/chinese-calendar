import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftUI

struct DynastyBoundarySourceDetailsView: View {
    let claimedStartDate: ChineseDateExpression
    let orthodoxStartDate: ChineseDateExpression?
    let claimedEndDate: ChineseDateExpression
    let orthodoxEndDate: ChineseDateExpression?
    let note: String?

    var body: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 10) {
                detail("自称开始", date: claimedStartDate)
                detail("正统开始", date: orthodoxStartDate)
                detail("自称结束", date: claimedEndDate)
                detail("正统结束", date: orthodoxEndDate)

                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
        } label: {
            Label("来源和精度", systemSymbol: .infoCircle)
                .font(.callout)
        }
    }

    private func detail(_ title: String, date: ChineseDateExpression?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
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
            return "年精度"
        case .month:
            return "月精度"
        case .day:
            return "日精度"
        case .range:
            return "范围精度"
        case .unknown:
            return "精度未知"
        }
    }
}
