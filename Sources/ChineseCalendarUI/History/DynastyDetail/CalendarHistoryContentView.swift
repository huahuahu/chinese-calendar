import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 中栏选择资料种类；只有选择动作会替换右栏根页面，不向前栏增加 push 栈。
struct CalendarHistoryContentView: View {
    @Binding var selection: CalendarHistorySection?
    @Query private var periods: [OrthodoxPeriod]

    init(orthodoxPeriodID: String, selection: Binding<CalendarHistorySection?>) {
        _selection = selection
        _periods = Query(filter: #Predicate<OrthodoxPeriod> { $0.id == orthodoxPeriodID })
    }

    var body: some View {
        if let period = periods.first, let dynasty = period.dynasty {
            List(selection: $selection) {
                sectionRow(
                    .emperors, title: CalendarStringKey.History.EmperorList.title,
                    value: String(dynasty.emperors.count), symbol: .personCropCircle
                )
                sectionRow(
                    .reignEras, title: CalendarStringKey.History.ReignEraList.title,
                    value: String(dynasty.emperors.reduce(0) { $0 + $1.reignEras.count }), symbol: .textBookClosed
                )
                sectionRow(
                    .orthodoxSpan, title: CalendarStringKey.History.DynastySpan.title,
                    value: HistoryDateRangeFormatter.orthodoxPeriodRange(
                        start: period.startBoundary?.date, end: period.endBoundary?.date
                    ),
                    symbol: .timelineSelection
                )
            }
            .navigationTitle(dynasty.shortName ?? dynasty.name)
        } else {
            ContentUnavailableView {
                Label(CalendarStringKey.History.DynastyDetail.Unavailable.title, systemSymbol: .buildingColumns)
            } description: {
                Text(CalendarStringKey.History.DynastyDetail.Unavailable.periodMessage)
            }
        }
    }

    private func sectionRow(
        _ section: CalendarHistorySection,
        title: LocalizedStringResource,
        value: String,
        symbol: SFSymbol
    ) -> some View {
        LabeledContent {
            Text(value)
                .monospacedDigit()
        } label: {
            Label(title, systemSymbol: symbol)
        }
        .tag(section)
    }
}
