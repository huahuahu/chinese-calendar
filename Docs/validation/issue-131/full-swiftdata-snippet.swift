
let url = URL(fileURLWithPath: "/path/to/schema-1.3-full.sqlite")
let container = try ChineseCalendarModelContainerFactory.makeContainer(at: url, allowsSave: false)
let context = ModelContext(container)
try ChineseCalendarRelationshipValidation.validate(in: context)
print("Full days",try context.fetchCount(FetchDescriptor<ChineseLunarDay>()))
var times:[Double]=[]
var count=0
for index in stride(from:0,through:29943,by:30) {
 let start=Date()
 let days=try context.fetch(FetchDescriptor<ChineseLunarDay>(predicate:ChineseCalendarRelationshipPredicates.days(inMonth:index),sortBy:[SortDescriptor(\.dayNumberInMonth)]))
 count += days.count
 times.append(Date().timeIntervalSince(start)*1000)
}
times.sort()
print("Indexed days samples",times.count,"rows",count,"median ms",times[times.count/2],"P95 ms",times[Int(Double(times.count)*0.95)])
times=[]
for year in stride(from:-220,through:2200,by:3) {
 let start=Date()
 _ = try context.fetch(FetchDescriptor<ChineseLunarMonth>(predicate:ChineseCalendarRelationshipPredicates.months(inYear:year),sortBy:[SortDescriptor(\.lunarMonthIndex)]))
 times.append(Date().timeIntervalSince(start)*1000)
}
times.sort()
print("Indexed months samples",times.count,"median ms",times[times.count/2],"P95 ms",times[Int(Double(times.count)*0.95)])
let resolver=CalendarSelectionResolver(modelContext:context)
for index in [9,10,11,27773,27774,27775,2780,2781] {
 let day=try resolver.selectedDayIndex(inMonth:index,todayJulianDayNumber:2461317)
 print("Selected month",index,"day",day as Any,"derived",try resolver.monthIndex(forDayIndex:day) as Any,"year",try resolver.yearNumber(forDayIndex:day) as Any)
}
