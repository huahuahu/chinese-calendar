@testable import ChineseCalendarData
import Testing

@Test func 干支年暴露标准名称() {
    let first = 干支年(周期: 1, 序号: 0)
    let last = 干支年(周期: 1, 序号: 59)

    #expect(first.名称 == "甲子")
    #expect(first.天干值 == .甲)
    #expect(first.地支值 == .子)
    #expect(last.名称 == "癸亥")
}

@Test func 干支年可以从中文名称构造() {
    let year = 干支年(周期: 78, 名称: "甲子")
    let invalid = 干支年(周期: 78, 名称: "甲甲")

    #expect(year?.周期 == 78)
    #expect(year?.序号 == 0)
    #expect(invalid == nil)
}

@Test func 农历月保留闰月显示() {
    let regularMonth = 农历月(月序: .六月)
    let leapMonth = 农历月(月序: .六月, 是闰月: true)

    #expect(regularMonth.中文名 == "六月")
    #expect(leapMonth.中文名 == "闰六月")
}

@Test func 干支历日期默认使用正月初一年界() {
    let date = 干支历日期(
        年: 干支年(周期: 1, 序号: 0),
        月: 农历月(月序: .正月),
        日: .初一,
        年号: "漢武帝太初元年"
    )

    #expect(date.年界规则 == .正月初一)
    #expect(date.年.名称 == "甲子")
    #expect(date.月.中文名 == "正月")
    #expect(date.日 == .初一)
    #expect(date.年号 == "漢武帝太初元年")
}
