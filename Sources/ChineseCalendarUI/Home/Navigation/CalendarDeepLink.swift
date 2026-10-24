import Foundation

enum CalendarDeepLink: Equatable {
    case lunarYear(Int, monthIndex: Int? = nil)
    case dynasty(orthodoxPeriodID: String)
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
        let parts = url.destinationParts

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

            return .dynasty(orthodoxPeriodID: parts[1])
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
}

private extension URL {
    var destinationParts: [String] {
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
