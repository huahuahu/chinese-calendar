import OSLog

public enum ChineseCalendarLog {
    public static let subsystem = "com.tiger.suzhou.ChineseCalendar"

    public static let app = logger(for: .app)
    public static let core = logger(for: .core)
    public static let data = logger(for: .data)
    public static let persistence = logger(for: .persistence)
    public static let ui = logger(for: .ui)
    public static let importPipeline = logger(for: .importPipeline)

    public static func logger(for module: Module) -> Logger {
        logger(category: module.category)
    }

    public static func logger(category: String) -> Logger {
        Logger(subsystem: subsystem, category: category)
    }
}

public extension ChineseCalendarLog {
    enum Module: String, CaseIterable, Sendable {
        case app
        case core
        case data
        case persistence
        case ui
        case importPipeline = "import"

        public var category: String {
            rawValue
        }
    }
}
