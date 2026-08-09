import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 显示在历史标签页中，用于浏览按顺序排列的正统时期时间线。
struct CalendarHistoryHomeView: View {
    @Query(sort: \OrthodoxPeriod.sequenceIndex) private var periods: [OrthodoxPeriod]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("历史")
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.tint)
                    Text("正统时间线")
                        .font(.largeTitle)
                        .bold()
                    Text("按朝代顺序浏览政治时间线，列表中直接显示皇帝数和年号数。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background.secondary, in: RoundedRectangle(cornerRadius: 28))

                content
            }
            .padding()
            .frame(maxWidth: 760, alignment: .leading)
        }
        .background(.calendarSystemBackground)
        .navigationTitle("历史")
    }

    @ViewBuilder
    private var content: some View {
        if periods.isEmpty {
            ContentUnavailableView(
                label: {
                    Label("没有历史时间线数据", systemSymbol: .timelineSelection)
                },
                description: {
                    Text("当前 SwiftData store 中没有可显示的正统时期。")
                }
            )
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 28))
        } else {
            LazyVStack(alignment: .leading, spacing: 12) {
                ForEach(periods, id: \.id) { period in
                    if let dynastyID = period.dynasty?.id {
                        NavigationLink(value: CalendarRoute.dynasty(dynastyID)) {
                            OrthodoxPeriodRow(period: period)
                        }
                        .buttonStyle(.plain)
                    } else {
                        OrthodoxPeriodRow(period: period)
                    }
                }
            }
        }
    }
}
