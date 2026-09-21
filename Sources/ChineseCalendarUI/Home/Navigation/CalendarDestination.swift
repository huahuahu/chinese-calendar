enum CalendarDestination: Hashable, Identifiable {
    case lunarYear(Int, monthIndex: Int? = nil, dayIndex: Int? = nil)
    case yearPicker(CalendarYearPickerDestination)
    case dynasty(orthodoxPeriodID: String)
    case emperorList(dynastyID: String)
    case reignEraList(dynastyID: String)
    case dynastySpan(orthodoxPeriodID: String)
    case reignEra(reignEraID: String)
    case emperor(String)

    var id: String {
        switch self {
        case let .lunarYear(yearNumber, monthIndex, dayIndex):
            "lunar-year-\(yearNumber)-\(monthIndex.map(String.init) ?? "none")-\(dayIndex.map(String.init) ?? "none")"
        case let .yearPicker(yearPicker):
            "year-picker-\(yearPicker.id)"
        case let .dynasty(orthodoxPeriodID):
            "dynasty-\(orthodoxPeriodID)"
        case let .emperorList(dynastyID):
            "emperor-list-\(dynastyID)"
        case let .reignEraList(dynastyID):
            "reign-era-list-\(dynastyID)"
        case let .dynastySpan(orthodoxPeriodID):
            "dynasty-span-\(orthodoxPeriodID)"
        case let .reignEra(reignEraID):
            "reign-era-\(reignEraID)"
        case let .emperor(emperorID):
            "emperor-\(emperorID)"
        }
    }

    var lunarYearNumber: Int? {
        switch self {
        case let .lunarYear(yearNumber, _, _):
            yearNumber
        case .yearPicker, .dynasty, .emperorList, .reignEraList, .dynastySpan, .reignEra, .emperor:
            nil
        }
    }
}
