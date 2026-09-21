#if DEBUG
    import ChineseCalendarPersistence
    import SwiftUI

    struct LunarDayGridPreviewContent: View {
        let days: [ChineseLunarDay]
        @Binding var selectedDayIndex: Int

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: "农历月格")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Text(verbatim: "连续日序")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                LunarDayGridLayout {
                    ForEach(days, id: \.dayIndex) { day in
                        Button {
                            selectedDayIndex = day.dayIndex
                        } label: {
                            LunarDayGridCell(
                                day: day,
                                isSelected: day.dayIndex == selectedDayIndex,
                                isToday: day.dayIndex == 2
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(.background.secondary, in: RoundedRectangle(cornerRadius: 28))
            // Match the page padding outside LunarMonthGrid as well as its own padding.
            .padding()
        }
    }
#endif
