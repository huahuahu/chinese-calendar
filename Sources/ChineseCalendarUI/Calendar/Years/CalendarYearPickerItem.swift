import ChineseCalendarPersistence

enum CalendarYearPickerItem: Identifiable {
    enum ID: Hashable {
        case section(Int)
        case year(Int)

        var sectionID: Int {
            switch self {
            case let .section(sectionID):
                sectionID
            case let .year(yearNumber):
                CalendarYearSection.signedCentury(lunarYearNumber: yearNumber)
            }
        }
    }

    case section(CalendarYearSection)
    case year(ChineseLunarYear)

    var id: ID {
        switch self {
        case let .section(section):
            .section(section.id)
        case let .year(year):
            .year(year.lunarYearNumber)
        }
    }

    static func items(for sections: [CalendarYearSection]) -> [Self] {
        sections.flatMap { section in
            [.section(section)] + section.years.map(Self.year)
        }
    }
}
