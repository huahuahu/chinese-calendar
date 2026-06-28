import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

struct DynastyDetailView: View {
    @Query private var dynasties: [Dynasty]

    init(dynastyID: String) {
        let dynastyID = dynastyID
        _dynasties = Query(
            filter: #Predicate<Dynasty> { dynasty in
                dynasty.id == dynastyID
            }
        )
    }

    var body: some View {
        if let dynasty {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dynasty.name)
                            .font(.largeTitle)
                            .bold()

                        if let note = dynasty.note {
                            Text(note)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }

                    LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                        DynastyFactCard(title: "皇帝", value: "\(emperors.count) 位")
                        DynastyFactCard(title: "年号", value: "\(reignEraCount) 个")
                        DynastyFactCard(title: "短名", value: dynasty.shortName ?? dynasty.name)
                    }

                    ChineseDateExpressionSummaryView(title: "自称开始", date: dynasty.claimedStartDate)
                    ChineseDateExpressionSummaryView(title: "自称结束", date: dynasty.claimedEndDate)

                    if !emperors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("皇帝")
                                .font(.title2)
                                .bold()

                            ForEach(emperors, id: \.id) { emperor in
                                EmperorSummaryRow(emperor: emperor)
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 760, alignment: .leading)
            }
            .navigationTitle(dynasty.shortName ?? dynasty.name)
        } else {
            ContentUnavailableView {
                Label("没有找到朝代", systemSymbol: .buildingColumns)
            } description: {
                Text("这个朝代记录不在当前 SwiftData store 中。")
            }
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 12)]
    }

    private var dynasty: Dynasty? {
        dynasties.first
    }

    private var emperors: [Emperor] {
        dynasty?.emperors.sorted {
            ($0.sequenceIndex, $0.id) < ($1.sequenceIndex, $1.id)
        } ?? []
    }

    private var reignEraCount: Int {
        emperors.reduce(0) { count, emperor in
            count + emperor.reignEras.count
        }
    }
}
