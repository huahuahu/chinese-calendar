import ChineseCalendarPersistence
import SFSafeSymbols
import SwiftData
import SwiftUI

/// 按领域顺序展示一个朝代的皇帝；卡片本期不继续导航。
struct EmperorListView: View {
    // swiftformat:disable:next enumNamespaces
    private struct Constants {
        static let listSpacing: CGFloat = 0
        static let horizontalPadding: CGFloat = 18
        static let summaryHorizontalInset: CGFloat = 2
        static let summaryBottomPadding: CGFloat = 12
        static let separatorHeight: CGFloat = 1
        static let contentVerticalPadding: CGFloat = 12
        static let maximumContentWidth: CGFloat = 760
    }

    @Query private var dynasties: [Dynasty]
    @Query private var emperors: [Emperor]

    init(dynastyID: String) {
        let dynastyID = dynastyID
        _dynasties = Query(
            filter: #Predicate<Dynasty> { dynasty in
                dynasty.id == dynastyID
            }
        )
        _emperors = Query(
            filter: #Predicate<Emperor> { emperor in
                emperor.dynasty.id == dynastyID
            },
            sort: \Emperor.sequenceIndex
        )
    }

    var body: some View {
        pageContent
    }

    @ViewBuilder
    private var pageContent: some View {
        if dynasties.isEmpty {
            missingDynastyState
        } else {
            emperorListPage
        }
    }

    private var emperorListPage: some View {
        ScrollView {
            emperorListContent
        }
        .navigationTitle("帝王")
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
        #endif
    }

    private var emperorListContent: some View {
        LazyVStack(alignment: .leading, spacing: Constants.listSpacing) {
            listSummary
            emperorRows
        }
        .padding(.horizontal, Constants.horizontalPadding)
        .padding(.vertical, Constants.contentVerticalPadding)
        .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
    }

    private var listSummary: some View {
        Text("\(emperors.count) 位皇帝 · \(reignSegmentCount) 段纪年")
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Constants.summaryHorizontalInset)
            .padding(.bottom, Constants.summaryBottomPadding)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: Constants.separatorHeight)
            }
    }

    @ViewBuilder
    private var emperorRows: some View {
        if emperors.isEmpty {
            emptyEmperorListState
        } else {
            ForEach(emperors, id: \.id) { emperor in
                EmperorCard(model: EmperorCardModel(emperor: emperor))
            }
        }
    }

    private var emptyEmperorListState: some View {
        ContentUnavailableView {
            Label("没有帝王资料", systemSymbol: .personCropCircleBadgeQuestionmark)
        } description: {
            Text("当前 store 中没有这个朝代的皇帝记录。")
        }
        .frame(maxWidth: .infinity)
    }

    private var missingDynastyState: some View {
        ContentUnavailableView {
            Label("没有找到朝代", systemSymbol: .buildingColumns)
        } description: {
            Text("这个朝代记录不在当前 SwiftData store 中。")
        }
    }

    private var reignSegmentCount: Int {
        emperors.reduce(0) { count, emperor in
            count + emperor.reignSegments.count
        }
    }
}

#Preview {
    NavigationStack {
        EmperorListView(dynastyID: HistoryPreviewData.dynastyID)
    }
    .modelContainer(HistoryPreviewData.container)
}
