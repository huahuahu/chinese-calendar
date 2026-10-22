import ChineseCalendarLocalization
import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 详情根只解析稳定路由中的时期与资料种类，继续导航由外层 NavigationScopeView 管理。
struct CalendarHistoryDetailView: View {
    let section: CalendarHistorySection?
    @Query private var periods: [OrthodoxPeriod]

    init(orthodoxPeriodID: String, section: CalendarHistorySection?) {
        self.section = section
        _periods = Query(filter: #Predicate<OrthodoxPeriod> { $0.id == orthodoxPeriodID })
    }

    var body: some View {
        if let period = periods.first, let dynasty = period.dynasty {
            switch section {
            case .emperors:
                EmperorListView(dynastyID: dynasty.id)
            case .reignEras:
                ReignEraListView(dynastyID: dynasty.id)
            case .orthodoxSpan:
                DynastySpanDetailView(orthodoxPeriodID: period.id)
            case nil:
                CalendarHistoryEmptyDetailView()
            }
        } else {
            ContentUnavailableView {
                Label(CalendarStringKey.History.DynastyDetail.Unavailable.title, systemSymbol: .buildingColumns)
            } description: {
                Text(CalendarStringKey.History.DynastyDetail.Unavailable.periodMessage)
            }
        }
    }
}
