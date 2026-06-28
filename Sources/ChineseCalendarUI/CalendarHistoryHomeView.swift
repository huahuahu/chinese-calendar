import ChineseCalendarPersistence
import SwiftData
import SwiftUI

struct CalendarHistoryHomeView: View {
    @Query(sort: \OrthodoxPeriod.sequenceIndex) private var periods: [OrthodoxPeriod]

    var body: some View {
        List {
            if periods.isEmpty {
                ContentUnavailableView(
                    "没有历史时间线数据",
                    systemImage: "timeline.selection",
                    description: Text("当前 SwiftData store 中没有可显示的正统时期。")
                )
            } else {
                Section("主流中国王朝序列") {
                    ForEach(periods, id: \.id) { period in
                        if let dynastyID = period.dynasty?.id {
                            NavigationLink(value: CalendarRoute.dynasty(dynastyID)) {
                                OrthodoxPeriodRow(period: period)
                            }
                        } else {
                            OrthodoxPeriodRow(period: period)
                        }
                    }
                }
            }
        }
        .navigationTitle("历史")
    }
}
