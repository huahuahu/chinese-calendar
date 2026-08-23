import ChineseCalendarPersistence

struct CalendarYearSection: Identifiable {
    /// 公元世纪为正数，公元前世纪为负数；不存在 0 世纪。
    let id: Int
    let years: [ChineseLunarYear]

    var title: String {
        if id < 0 {
            "公元前 \(-id) 世纪"
        } else {
            "公元 \(id) 世纪"
        }
    }

    var indexTitle: String {
        if id < 0 {
            "前\(-id)"
        } else {
            "\(id)"
        }
    }

    static func sections(for years: [ChineseLunarYear]) -> [Self] {
        Dictionary(grouping: years) { year in
            signedCentury(lunarYearNumber: year.lunarYearNumber)
        }
        .map { century, years in
            Self(id: century, years: years)
        }
        .sorted { $0.id < $1.id }
    }

    static func signedCentury(lunarYearNumber: Int) -> Int {
        if lunarYearNumber > 0 {
            (lunarYearNumber - 1) / 100 + 1
        } else {
            -(1 - lunarYearNumber / 100)
        }
    }
}
