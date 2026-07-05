import Foundation

enum CalendarRoute: Hashable, Identifiable {
    case lunarYear(Int)
    case dynasty(String)
    case emperor(String)

    var id: String {
        switch self {
        case let .lunarYear(yearNumber):
            "lunar-year-\(yearNumber)"
        case let .dynasty(dynastyID):
            "dynasty-\(dynastyID)"
        case let .emperor(emperorID):
            "emperor-\(emperorID)"
        }
    }

    var lunarYearNumber: Int? {
        switch self {
        case let .lunarYear(yearNumber):
            yearNumber
        case .dynasty, .emperor:
            nil
        }
    }
}

enum CalendarDeepLink: Equatable {
    case lunarYear(Int, monthIndex: Int? = nil)
    case dynasty(String)
    case emperor(String)
}

enum CalendarDeepLinkParser {
    static func deepLink(from url: URL) -> CalendarDeepLink? {
        guard url.scheme == "chinesecalendar" || url.scheme == "chinese-calendar" else {
            return nil
        }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        let monthIndex = queryItems.intValue(for: "monthIndex") ?? queryItems.intValue(for: "month")
        let parts = url.routeParts

        guard let firstPart = parts.first else {
            return nil
        }

        switch firstPart {
        case "year", "lunar-year":
            guard parts.count >= 2, let yearNumber = Int(parts[1]) else {
                return nil
            }

            return .lunarYear(yearNumber, monthIndex: monthIndex)
        case "dynasty":
            guard parts.count >= 2 else {
                return nil
            }

            return .dynasty(parts[1])
        case "emperor":
            guard parts.count >= 2 else {
                return nil
            }

            return .emperor(parts[1])
        default:
            guard let yearNumber = Int(firstPart) else {
                return nil
            }

            return .lunarYear(yearNumber, monthIndex: monthIndex)
        }
    }

    static func deepLink(from launchArguments: [String]) -> CalendarDeepLink? {
        guard let deepLinkFlagIndex = launchArguments.firstIndex(of: "--deep-link") else {
            return nil
        }

        let urlIndex = launchArguments.index(after: deepLinkFlagIndex)
        guard launchArguments.indices.contains(urlIndex), let url = URL(string: launchArguments[urlIndex]) else {
            return nil
        }

        return deepLink(from: url)
    }
}

private extension URL {
    var routeParts: [String] {
        var parts: [String] = []

        if let host, !host.isEmpty {
            parts.append(host)
        }

        parts.append(contentsOf: pathComponents.filter { $0 != "/" })
        return parts
    }
}

private extension [URLQueryItem] {
    func intValue(for name: String) -> Int? {
        first { $0.name == name }.flatMap { item in
            item.value.flatMap(Int.init)
        }
    }
}
