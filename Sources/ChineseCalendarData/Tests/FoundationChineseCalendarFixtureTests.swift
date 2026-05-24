// swiftlint:disable identifier_name superfluous_disable_command
import Foundation
import Testing

@Test func 苹果农历从唐代开始匹配样本数据() throws {
    let samples = calendarDaySamples
    let ancientSampleIDs = Set<CalendarDaySampleID>([.数据集起点, .汉武帝登基])
    let samplesFromTangForward = samples.filter { ancientSampleIDs.contains($0.id) == false }

    #expect(samplesFromTangForward.count == samples.count - ancientSampleIDs.count)

    for sample in samplesFromTangForward {
        let foundationDate = try foundationChineseDate(for: sample)

        #expect(
            foundationDate == sample.expected.foundationComparableDate,
            "\(sample.id.名称) 应该与苹果中国农历的月、闰月、日一致。"
        )
    }
}

@Test func 苹果农历保留上古样本差异说明() throws {
    let expectedFoundationDates = [
        CalendarDaySampleID.数据集起点: FoundationChineseDate(month: 12, isLeapMonth: false, day: 5),
        .汉武帝登基: FoundationChineseDate(month: 1, isLeapMonth: false, day: 28)
    ]

    for sampleID in [CalendarDaySampleID.数据集起点, .汉武帝登基] {
        let sample = try #require(calendarDaySamples.first { $0.id == sampleID })
        let expectedFoundationDate = try #require(expectedFoundationDates[sampleID])
        let foundationDate = try foundationChineseDate(for: sample)

        #expect(foundationDate == expectedFoundationDate)
        #expect(
            foundationDate != sample.expected.foundationComparableDate,
            "\(sample.id.名称) 特意保留为苹果中国农历对照范围之外的已知差异。"
        )
    }
}

private struct CalendarDaySample {
    let id: CalendarDaySampleID
    let expected: ExpectedCalendarDay
}

private enum CalendarDaySampleID: Hashable {
    case 数据集起点
    case 汉武帝登基
    case 安史之乱爆发
    case 北宋建立
    case 明朝建立
    case 格里高利历改革前最后一天
    case 格里高利历改革后第一天
    case 李自成进入北京
    case 康熙帝即位
    case 第一次鸦片战争开始
    case 武昌起义
    case 中华民国成立
    case 中华人民共和国成立
    case 阿波罗十一号登月
    case 计算机时间纪元
    case 二零零零年闰日
    case 北京奥运会开幕
    case 二零一七闰六月开始
    case 二一零零非闰年边界
    case 数据集终点

    var 名称: String {
        switch self {
        case .数据集起点:
            "数据集起点"
        case .汉武帝登基:
            "汉武帝登基"
        case .安史之乱爆发:
            "安史之乱爆发"
        case .北宋建立:
            "北宋建立"
        case .明朝建立:
            "明朝建立"
        case .格里高利历改革前最后一天:
            "格里高利历改革前最后一天"
        case .格里高利历改革后第一天:
            "格里高利历改革后第一天"
        case .李自成进入北京:
            "李自成进入北京"
        case .康熙帝即位:
            "康熙帝即位"
        case .第一次鸦片战争开始:
            "第一次鸦片战争开始"
        case .武昌起义:
            "武昌起义"
        case .中华民国成立:
            "中华民国成立"
        case .中华人民共和国成立:
            "中华人民共和国成立"
        case .阿波罗十一号登月:
            "阿波罗11号登月"
        case .计算机时间纪元:
            "计算机时间纪元"
        case .二零零零年闰日:
            "2000年闰日"
        case .北京奥运会开幕:
            "北京奥运会开幕"
        case .二零一七闰六月开始:
            "2017闰六月开始"
        case .二一零零非闰年边界:
            "2100非闰年边界"
        case .数据集终点:
            "数据集终点"
        }
    }
}

private struct ExpectedCalendarDay {
    let julianDayNumber: Int
    let lunarMonth: ExpectedLunarMonth
    let lunarDay: ExpectedLunarDay

    var foundationComparableDate: FoundationChineseDate {
        FoundationChineseDate(
            month: lunarMonth.monthNumberInYear,
            isLeapMonth: lunarMonth.isLeapMonth,
            day: lunarDay.dayNumberInMonth
        )
    }
}

private struct ExpectedLunarMonth {
    let monthNumberInYear: Int
    let isLeapMonth: Bool
}

private struct ExpectedLunarDay {
    let dayNumberInMonth: Int
}

private struct FoundationChineseDate: Equatable {
    let month: Int
    let isLeapMonth: Bool
    let day: Int
}

private func foundationChineseDate(for sample: CalendarDaySample) throws -> FoundationChineseDate {
    var calendar = Calendar(identifier: .chinese)
    calendar.timeZone = try #require(TimeZone(secondsFromGMT: 8 * 60 * 60))

    let components = calendar.dateComponents(
        [.month, .day, .isLeapMonth],
        from: dateAtNoonUTC(julianDayNumber: sample.expected.julianDayNumber)
    )

    return try FoundationChineseDate(
        month: #require(components.month),
        isLeapMonth: components.isLeapMonth ?? false,
        day: #require(components.day)
    )
}

private func dateAtNoonUTC(julianDayNumber: Int) -> Date {
    let secondsPerDay = 86400
    let daysSinceUnixEpoch = julianDayNumber - 2_440_588
    let secondsAtNoon = daysSinceUnixEpoch * secondsPerDay + 12 * 60 * 60

    return Date(timeIntervalSince1970: TimeInterval(secondsAtNoon))
}

private let calendarDaySamples = [
    CalendarDaySample(
        id: .数据集起点,
        expected: ExpectedCalendarDay(
            julianDayNumber: 1_640_703,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 12, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 4)
        )
    ),
    CalendarDaySample(
        id: .汉武帝登基,
        expected: ExpectedCalendarDay(
            julianDayNumber: 1_669_991,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 1, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 27)
        )
    ),
    CalendarDaySample(
        id: .安史之乱爆发,
        expected: ExpectedCalendarDay(
            julianDayNumber: 1_997_171,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 11, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 9)
        )
    ),
    CalendarDaySample(
        id: .北宋建立,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_071_732,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 1, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 5)
        )
    ),
    CalendarDaySample(
        id: .明朝建立,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_220_742,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 1, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 4)
        )
    ),
    CalendarDaySample(
        id: .格里高利历改革前最后一天,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_299_160,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 9, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 18)
        )
    ),
    CalendarDaySample(
        id: .格里高利历改革后第一天,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_299_161,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 9, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 19)
        )
    ),
    CalendarDaySample(
        id: .李自成进入北京,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_321_634,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 3, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 19)
        )
    ),
    CalendarDaySample(
        id: .康熙帝即位,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_327_764,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 1, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 7)
        )
    ),
    CalendarDaySample(
        id: .第一次鸦片战争开始,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_392_987,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 7, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 27)
        )
    ),
    CalendarDaySample(
        id: .武昌起义,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_419_320,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 8, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 19)
        )
    ),
    CalendarDaySample(
        id: .中华民国成立,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_419_403,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 11, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 13)
        )
    ),
    CalendarDaySample(
        id: .中华人民共和国成立,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_433_191,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 8, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 10)
        )
    ),
    CalendarDaySample(
        id: .阿波罗十一号登月,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_440_423,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 6, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 7)
        )
    ),
    CalendarDaySample(
        id: .计算机时间纪元,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_440_588,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 11, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 24)
        )
    ),
    CalendarDaySample(
        id: .二零零零年闰日,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_451_604,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 1, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 25)
        )
    ),
    CalendarDaySample(
        id: .北京奥运会开幕,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_454_687,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 7, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 8)
        )
    ),
    CalendarDaySample(
        id: .二零一七闰六月开始,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_457_958,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 6, isLeapMonth: true),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 1)
        )
    ),
    CalendarDaySample(
        id: .二一零零非闰年边界,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_488_129,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 1, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 21)
        )
    ),
    CalendarDaySample(
        id: .数据集终点,
        expected: ExpectedCalendarDay(
            julianDayNumber: 2_524_958,
            lunarMonth: ExpectedLunarMonth(monthNumberInYear: 11, isLeapMonth: false),
            lunarDay: ExpectedLunarDay(dayNumberInMonth: 25)
        )
    )
]

// swiftlint:enable identifier_name superfluous_disable_command
