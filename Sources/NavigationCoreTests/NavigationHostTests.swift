import Foundation
@testable import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("根宿主配置与页面环境")
struct NavigationHostTests {
    fileprivate enum Tab: Hashable { case home, history }
    fileprivate enum Route: Hashable { case detail, tabs }
    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>
    fileprivate typealias Key = NavigationConfigurationKey<Tab, Route, NoNavigationAlert>

    @Test func configurationDefaultsToAbsentAndEnvironmentCopiesStayIndependent() throws {
        let recorder = HostTestRecorder()
        var first = EnvironmentValues()
        #expect(first[navigation: Key()] == nil)
        first[navigation: Key()] = HostTestConfiguration(name: "first", recorder: recorder)
        var second = first
        second[navigation: Key()] = HostTestConfiguration(name: "second", recorder: recorder)

        #expect(try #require(first[navigation: Key()] as? HostTestConfiguration).name == "first")
        #expect(try #require(second[navigation: Key()] as? HostTestConfiguration).name == "second")
        #expect(EnvironmentValues()[navigation: Key()] == nil)
    }

    @Test func nearestHostWinsForIdenticalRouteTypesAndPagesReadLocalEnvironment() {
        let outer = Router(selectedScope: .home)
        let inner = Router(selectedScope: .history)
        let recorder = HostTestRecorder()
        let content = VStack {
            HostTestConfiguredPage()
                .environment(\.locale, Locale(identifier: "zh_CN"))
            HostTestConfiguredPage()
                .environment(\.locale, Locale(identifier: "en_US"))
            HostTestConfiguredPage()
                .navigationHost(
                    context: inner.rootPresentation,
                    configuration: HostTestConfiguration(name: "inner", recorder: recorder)
                )
                .environment(\.locale, Locale(identifier: "ja_JP"))
        }
        .navigationHost(
            context: outer.rootPresentation,
            configuration: HostTestConfiguration(name: "outer", recorder: recorder)
        )

        #expect(ImageRenderer(content: content).cgImage != nil)
        #expect(Set(recorder.pages) == ["outer:zh_CN", "outer:en_US", "inner:ja_JP"])
        #expect(outer.snapshot.paths.isEmpty)
        #expect(inner.snapshot.paths.isEmpty)
    }

    @Test func pageMethodBuildsFromAnExistentialConfiguration() {
        let recorder = HostTestRecorder()
        let configuration: any NavigationHostConfiguration<Tab, Route, NoNavigationAlert> =
            HostTestDefaultConfiguration(recorder: recorder)
        let content = configuration.page(for: .detail)
            .environment(\.locale, Locale(identifier: "zh_TW"))

        #expect(ImageRenderer(content: content).cgImage != nil)
        #expect(Set(recorder.pages) == ["default:zh_TW"])
        #expect(configuration.providesNavigationStack(for: .detail))
        #expect(configuration.confirmationContent(for: .selectScope(.home)) == nil)
    }

    @Test func modalEntryUsesTheSameBuilderAndInheritsTheHostEnvironment() throws {
        let router = Router(selectedScope: .home)
        let recorder = HostTestRecorder()
        #expect(router.rootPresentation.present(.tabs, initialStack: .scope(.home)))
        let node = try #require(router.presentedNode)
        let modal = router.presentationContext(for: node)
        let content = NavigationPresentationNodeView(node: node, context: modal)
            .navigationHost(
                context: router.rootPresentation,
                configuration: HostTestConfiguration(name: "shared", recorder: recorder)
            )
            .environment(\.locale, Locale(identifier: "zh_CN"))

        #expect(ImageRenderer(content: content).cgImage != nil)
        #expect(Set(recorder.pages) == ["shared:zh_CN"])
    }

    @Test func configurationSupportsModalTabsWithoutChangingContextOwnership() throws {
        let router = Router(selectedScope: .home)
        let independent = Router(selectedScope: .home)
        let configuration = HostTestConfiguration(name: "shared", recorder: HostTestRecorder())
        #expect(!configuration.providesNavigationStack(for: .tabs))
        #expect(configuration.providesNavigationStack(for: .detail))
        #expect(router.rootPresentation.present(.tabs, initialStack: .scope(.history)))
        let modal = try router.presentationContext(for: #require(router.presentedNode))
        let modalHistory = modal.context(for: .scope(.history))
        #expect(modalHistory.push(.detail))
        #expect(router.context(for: .history).path.isEmpty)
        #expect(modal.context(for: .scope(.home)).path.isEmpty)
        #expect(independent.context(for: .history).path.isEmpty)
        #expect(modal.dismiss())
        #expect(!modalHistory.push(.tabs))

        // 所有栈及节点只接收身份和根内容，不再接收 builder；配置不会改变状态归属。
        _ = NavigationScopeView(stack: .scope(.home), presentation: router.rootPresentation) { Color.clear }
            .navigationHost(context: router.rootPresentation, configuration: configuration)
    }
}

private final class HostTestRecorder {
    var pages: [String] = []
}

private struct HostTestDefaultConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = NavigationHostTests.Tab
    typealias Destination = NavigationHostTests.Route
    typealias AlertRoute = NoNavigationAlert
    let recorder: HostTestRecorder

    func destination(for destination: NavigationHostTests.Route) -> some View {
        HostTestPage(name: "default", recorder: recorder)
    }
}

private struct HostTestConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = NavigationHostTests.Tab
    typealias Destination = NavigationHostTests.Route
    typealias AlertRoute = NoNavigationAlert
    let name: String
    let recorder: HostTestRecorder

    func destination(for destination: NavigationHostTests.Route) -> some View {
        HostTestPage(name: name, recorder: recorder)
    }

    func providesNavigationStack(for destination: NavigationHostTests.Route) -> Bool {
        destination != .tabs
    }
}

private struct HostTestPage: View {
    let name: String
    let recorder: HostTestRecorder
    @Environment(\.locale) private var locale

    var body: some View {
        _ = recorder.pages.append("\(name):\(locale.identifier)")
        return Color.clear.frame(width: 10, height: 10)
    }
}

private struct HostTestConfiguredPage: View {
    @Environment(\.[navigation: NavigationHostTests.Key()]) private var configuration

    var body: some View {
        if let configuration {
            configuration.page(for: .detail)
        } else {
            missingNavigationConfiguration()
        }
    }
}
