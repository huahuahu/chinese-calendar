import Foundation
import Observation

/// A presented destination that owns an independent push path and nested presentations.
@MainActor
@Observable
public final class NavigationPresentationNode<Destination: Hashable>: Identifiable {
    public let id: UUID
    public let destination: Destination
    public var path: [Destination]
    public var sheet: NavigationPresentationNode?
    public var fullScreen: NavigationPresentationNode?

    public init(
        id: UUID = UUID(),
        destination: Destination,
        path: [Destination] = []
    ) {
        self.id = id
        self.destination = destination
        self.path = path
    }

    public func push(_ destination: Destination) {
        path.append(destination)
        let pathCount = path.count
        NavigationCoreLog.logger.debug("Pushed destination; presentation path count: \(pathCount)")
    }

    public func presentSheet(_ destination: Destination) {
        sheet = NavigationPresentationNode(destination: destination)
        NavigationCoreLog.logger.debug("Presented nested sheet")
    }

    public func presentFullScreen(_ destination: Destination) {
        fullScreen = NavigationPresentationNode(destination: destination)
        NavigationCoreLog.logger.debug("Presented nested full screen")
    }

    public func dismissSheet() {
        sheet = nil
        NavigationCoreLog.logger.debug("Dismissed nested sheet")
    }

    public func dismissFullScreen() {
        fullScreen = nil
        NavigationCoreLog.logger.debug("Dismissed nested full screen")
    }

    /// Dismisses the frontmost sheet in this presentation subtree.
    @discardableResult
    public func dismissFrontmostSheet() -> Bool {
        if let fullScreen, fullScreen.dismissFrontmostSheet() {
            return true
        }

        guard let sheet else {
            return false
        }

        if sheet.dismissFrontmostSheet() {
            return true
        }

        self.sheet = nil
        NavigationCoreLog.logger.debug("Dismissed frontmost nested sheet")
        return true
    }

    public var frontmostPresentationNode: NavigationPresentationNode {
        if let fullScreen {
            return fullScreen.frontmostPresentationNode
        }

        if let sheet {
            return sheet.frontmostPresentationNode
        }

        return self
    }
}
