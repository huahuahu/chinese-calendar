#if canImport(OSLog)
import OSLog
#else
public enum LogPrivacy: Sendable {
    case `private`
    case `public`
}

public struct LogMessage: ExpressibleByStringInterpolation, ExpressibleByStringLiteral, Sendable {
    public let description: String

    public init(stringLiteral value: String) {
        description = value
    }

    public init(stringInterpolation: StringInterpolation) {
        description = stringInterpolation.output
    }

    public struct StringInterpolation: StringInterpolationProtocol {
        fileprivate var output = ""

        public init(literalCapacity: Int, interpolationCount: Int) {
            output.reserveCapacity(literalCapacity + interpolationCount * 8)
        }

        public mutating func appendLiteral(_ literal: String) {
            output += literal
        }

        public mutating func appendInterpolation<T>(_ value: T) {
            output += String(describing: value)
        }

        public mutating func appendInterpolation<T>(_ value: T, privacy _: LogPrivacy) {
            output += String(describing: value)
        }
    }
}

public struct Logger: Sendable {
    private let subsystem: String
    private let category: String

    public init(subsystem: String, category: String) {
        self.subsystem = subsystem
        self.category = category
    }

    public func debug(_ message: LogMessage) { log(level: "DEBUG", message) }
    public func info(_ message: LogMessage) { log(level: "INFO", message) }
    public func notice(_ message: LogMessage) { log(level: "NOTICE", message) }
    public func error(_ message: LogMessage) { log(level: "ERROR", message) }

    private func log(level: String, _ message: LogMessage) {
        Swift.print("[\(level)] [\(subsystem):\(category)] \(message.description)")
    }
}
#endif

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
