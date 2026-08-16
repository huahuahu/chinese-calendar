import Foundation
import Observation

/// 表示一个以 sheet 或全屏形式呈现、并拥有独立导航栈的节点。
@MainActor
@Observable
final class CalendarPresentationNode: Identifiable {
    let id = UUID()
    let destination: CalendarDestination
    var path: [CalendarDestination]
    var sheet: CalendarPresentationNode?
    var fullScreen: CalendarPresentationNode?

    init(
        destination: CalendarDestination,
        path: [CalendarDestination] = []
    ) {
        self.destination = destination
        self.path = path
    }

    func push(_ destination: CalendarDestination) {
        path.append(destination)
    }

    func presentSheet(_ destination: CalendarDestination) {
        sheet = CalendarPresentationNode(destination: destination)
    }

    func presentFullScreen(_ destination: CalendarDestination) {
        fullScreen = CalendarPresentationNode(destination: destination)
    }

    func dismissSheet() {
        sheet = nil
    }

    func dismissFullScreen() {
        fullScreen = nil
    }

    var frontmostPresentationNode: CalendarPresentationNode {
        if let fullScreen {
            return fullScreen.frontmostPresentationNode
        }

        if let sheet {
            return sheet.frontmostPresentationNode
        }

        return self
    }
}
