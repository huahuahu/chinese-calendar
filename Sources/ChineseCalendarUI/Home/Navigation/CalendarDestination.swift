enum CalendarDestination: Hashable, Identifiable {
    case lunarYear(Int, monthIndex: Int? = nil, dayIndex: Int? = nil)
    case yearPicker(CalendarYearPickerDestination)
    case dynasty(String)
    case emperor(String)

    var id: String {
        switch self {
        case let .lunarYear(yearNumber, monthIndex, dayIndex):
            "lunar-year-\(yearNumber)-\(monthIndex.map(String.init) ?? "none")-\(dayIndex.map(String.init) ?? "none")"
        case let .yearPicker(yearPicker):
            "year-picker-\(yearPicker.id)"
        case let .dynasty(dynastyID):
            "dynasty-\(dynastyID)"
        case let .emperor(emperorID):
            "emperor-\(emperorID)"
        }
    }

    var lunarYearNumber: Int? {
        switch self {
        case let .lunarYear(yearNumber, _, _):
            yearNumber
        case .yearPicker, .dynasty, .emperor:
            nil
        }
    }

}
