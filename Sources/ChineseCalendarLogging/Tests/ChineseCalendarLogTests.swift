@testable import ChineseCalendarLogging
import Testing

@Test func moduleCategoriesAreStable() {
    #expect(ChineseCalendarLog.Module.app.category == "app")
    #expect(ChineseCalendarLog.Module.core.category == "core")
    #expect(ChineseCalendarLog.Module.data.category == "data")
    #expect(ChineseCalendarLog.Module.persistence.category == "persistence")
    #expect(ChineseCalendarLog.Module.ui.category == "ui")
    #expect(ChineseCalendarLog.Module.importPipeline.category == "import")
}

@Test func subsystemUsesAppBundlePrefix() {
    #expect(ChineseCalendarLog.subsystem == "com.tiger.suzhou.ChineseCalendar")
}

@Test func exposesOneLoggerPerModule() {
    #expect(ChineseCalendarLog.Module.allCases.count == 6)
}
