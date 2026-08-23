import Observation

/// Stores navigation structure without interpreting scope or destination values.
@MainActor
@Observable
public final class NavigationRouter<Scope: Hashable, Destination: Hashable> {
    public var selectedScope: Scope
    public var rootDestinations: [Scope: Destination]
    public var paths: [Scope: [Destination]]
    public var sheet: NavigationPresentationNode<Destination>?
    public var fullScreen: NavigationPresentationNode<Destination>?

    public init(
        selectedScope: Scope,
        rootDestinations: [Scope: Destination] = [:],
        paths: [Scope: [Destination]] = [:]
    ) {
        self.selectedScope = selectedScope
        self.rootDestinations = rootDestinations
        self.paths = paths
    }

    public var hasActivePresentation: Bool {
        sheet != nil || fullScreen != nil
    }

    public var selectedDestination: Destination? {
        currentDestination(on: selectedScope)
    }

    public func rootDestination(for scope: Scope) -> Destination? {
        rootDestinations[scope]
    }

    public func setRootDestination(_ destination: Destination?, for scope: Scope) {
        rootDestinations[scope] = destination
        paths[scope] = []
        NavigationCoreLog.logger.debug("Set root destination and cleared scope path")
    }

    public func path(for scope: Scope) -> [Destination] {
        paths[scope] ?? []
    }

    public func setPath(_ path: [Destination], for scope: Scope) {
        paths[scope] = path
        NavigationCoreLog.logger.debug("Set scope path; path count: \(path.count)")
    }

    public func currentDestination(on scope: Scope) -> Destination? {
        path(for: scope).last ?? rootDestination(for: scope)
    }

    public func push(_ destination: Destination, on scope: Scope? = nil) {
        let targetScope = scope ?? selectedScope
        selectedScope = targetScope
        paths[targetScope, default: []].append(destination)
        let pathCount = paths[targetScope]?.count ?? 0
        NavigationCoreLog.logger.debug("Pushed destination; scope path count: \(pathCount)")
    }

    public func presentSheet(_ destination: Destination) {
        if let frontmostPresentationNode {
            frontmostPresentationNode.presentSheet(destination)
        } else {
            sheet = NavigationPresentationNode(destination: destination)
            NavigationCoreLog.logger.debug("Presented root sheet")
        }
    }

    public func presentFullScreen(_ destination: Destination) {
        if let frontmostPresentationNode {
            frontmostPresentationNode.presentFullScreen(destination)
        } else {
            fullScreen = NavigationPresentationNode(destination: destination)
            NavigationCoreLog.logger.debug("Presented root full screen")
        }
    }

    public func dismissSheet() {
        sheet = nil
        NavigationCoreLog.logger.debug("Dismissed root sheet")
    }

    public func dismissFullScreen() {
        fullScreen = nil
        NavigationCoreLog.logger.debug("Dismissed root full screen")
    }

    public var frontmostPresentationNode: NavigationPresentationNode<Destination>? {
        if let fullScreen {
            return fullScreen.frontmostPresentationNode
        }

        if let sheet {
            return sheet.frontmostPresentationNode
        }

        return nil
    }
}
