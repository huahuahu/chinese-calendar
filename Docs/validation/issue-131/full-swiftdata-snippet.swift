
let url = URL(fileURLWithPath: "/path/to/schema-1.4-full.sqlite")
let container = try ChineseCalendarModelContainerFactory.makeContainer(at: url, allowsSave: false)
let context = ModelContext(container)
try ChineseCalendarRelationshipValidation.validate(in: context)
try print("Full days", context.fetchCount(FetchDescriptor<ChineseLunarDay>()))
var times: [Double] = []
var count = 0
for index in stride(from: 0, through: 29943, by: 30) {
    let start = Date()
    var descriptor = FetchDescriptor<ChineseLunarMonth>(predicate: #Predicate { $0.lunarMonthIndex == index })
    descriptor.fetchLimit = 1
    guard let month = try context.fetch(descriptor).first else { continue }
    let days = ChineseCalendarRelationshipQueries.days(inMonth: month)
    count += days.count
    times.append(Date().timeIntervalSince(start) * 1000)
}

times.sort()
print(
    "Indexed days samples",
    times.count,
    "rows",
    count,
    "median ms",
    times[times.count / 2],
    "P95 ms",
    times[Int(Double(times.count) * 0.95)]
)
times = []
for year in stride(from: -220, through: 2200, by: 3) {
    let start = Date()
    var descriptor = FetchDescriptor<ChineseLunarYear>(predicate: #Predicate { $0.lunarYearNumber == year })
    descriptor.fetchLimit = 1
    guard let lunarYear = try context.fetch(descriptor).first else { continue }
    _ = ChineseCalendarRelationshipQueries.months(inYear: lunarYear)
    times.append(Date().timeIntervalSince(start) * 1000)
}

times.sort()
print(
    "Indexed months samples",
    times.count,
    "median ms",
    times[times.count / 2],
    "P95 ms",
    times[Int(Double(times.count) * 0.95)]
)
let resolver = CalendarSelectionResolver(modelContext: context)
for index in [9, 10, 11, 27773, 27774, 27775, 2780, 2781] {
    let day = try resolver.selectedDayIndex(inMonth: index, todayJulianDayNumber: 2_461_317)
    try print(
        "Selected month",
        index,
        "day",
        day as Any,
        "derived",
        resolver.monthIndex(forDayIndex: day) as Any,
        "year",
        resolver.yearNumber(forDayIndex: day) as Any
    )
}
