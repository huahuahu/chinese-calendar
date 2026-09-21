#if DEBUG
    import ChineseCalendarPersistence
    import SwiftUI

    struct LunarDayGridLayoutPreview: View {
        @State private var containerWidth: CGFloat = 393
        @State private var dynamicTypeSize = DynamicTypeSize.large
        @State private var selectedDayIndex = 1
        @State private var localeIdentifier = "zh_CN"
        @State private var days = Self.makeDays()

        var body: some View {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(verbatim: "容器宽度")
                        Slider(value: $containerWidth, in: 280 ... 980, step: 1) {
                            Text(verbatim: "容器宽度")
                        }
                        Text(verbatim: "\(Int(containerWidth)) pt")
                            .monospacedDigit()
                            .frame(width: 68, alignment: .trailing)
                    }

                    Picker(selection: $dynamicTypeSize) {
                        Text(verbatim: "默认").tag(DynamicTypeSize.large)
                        Text(verbatim: "最大常规").tag(DynamicTypeSize.xxxLarge)
                        Text(verbatim: "辅助功能 1").tag(DynamicTypeSize.accessibility1)
                        Text(verbatim: "辅助功能 5").tag(DynamicTypeSize.accessibility5)
                    } label: {
                        Text(verbatim: "字号")
                    }
                    .pickerStyle(.menu)

                    Picker(selection: $localeIdentifier) {
                        Text(verbatim: "中文").tag("zh_CN")
                        Text(verbatim: "English (US)").tag("en_US")
                    } label: {
                        Text(verbatim: "日期格式")
                    }
                    .pickerStyle(.menu)
                }
                .padding()

                Divider()

                // Horizontal scrolling belongs only to this adjustable preview canvas.
                ScrollView([.horizontal, .vertical]) {
                    LunarDayGridPreviewContent(
                        days: days,
                        selectedDayIndex: $selectedDayIndex
                    )
                    .environment(\.dynamicTypeSize, dynamicTypeSize)
                    .environment(\.locale, Locale(identifier: localeIdentifier))
                    .frame(width: containerWidth)
                    .padding(.vertical)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .background(.background)
        }

        /// Transient layout fixtures include January 1's longer civil date; no store is opened.
        static func makeDays() -> [ChineseLunarDay] {
            (1 ... 30).map { dayNumber in
                ChineseLunarDay(
                    dayIndex: dayNumber,
                    lunarMonthIndex: 0,
                    dayNumberInMonth: dayNumber,
                    dayStemIndex: (dayNumber - 1) % 10,
                    dayBranchIndex: (dayNumber - 1) % 12,
                    calendarDay: CalendarDay(
                        dayIndex: dayNumber,
                        julianDayNumber: 2_461_029 + dayNumber
                    )
                )
            }
        }
    }

    #Preview("日期网格实时预览", traits: .fixedLayout(width: 1024, height: 900)) {
        LunarDayGridLayoutPreview()
    }
#endif
