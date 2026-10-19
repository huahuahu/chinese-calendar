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
            HostTestConfiguredPage(isPresented: false)
                .environment(\.locale, Locale(identifier: "zh_CN"))
            HostTestConfiguredPage(isPresented: true)
                .environment(\.locale, Locale(identifier: "en_US"))
            HostTestConfiguredPage(isPresented: false)
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
        #expect(Set(recorder.pages) == ["outer:push:zh_CN", "outer:modal:en_US", "inner:push:ja_JP"])
        #expect(outer.snapshot.paths.isEmpty)
        #expect(inner.snapshot.paths.isEmpty)
    }

    @Test func defaultPresentedMappingReusesTheConfiguredPageBuilder() {
        let recorder = HostTestRecorder()
        let configuration = HostTestDefaultConfiguration(recorder: recorder)
        let content = NavigationConfiguredDestination(
            configuration: configuration, destination: .detail, isPresented: true
        )
        .environment(\.locale, Locale(identifier: "zh_TW"))

        #expect(ImageRenderer(content: content).cgImage != nil)
        #expect(Set(recorder.pages) == ["default:push:zh_TW"])
        #expect(configuration.providesNavigationStack(for: .detail))
        #expect(configuration.confirmationContent(for: .selectScope(.home)) == nil)
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
        HostTestPage(name: "default", mode: "push", recorder: recorder)
    }
}

private struct HostTestConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = NavigationHostTests.Tab
    typealias Destination = NavigationHostTests.Route
    typealias AlertRoute = NoNavigationAlert
    let name: String
    let recorder: HostTestRecorder

    func destination(for destination: NavigationHostTests.Route) -> some View {
        HostTestPage(name: name, mode: "push", recorder: recorder)
    }

    func presentedDestination(for destination: NavigationHostTests.Route) -> some View {
        HostTestPage(name: name, mode: "modal", recorder: recorder)
    }

    func providesNavigationStack(for destination: NavigationHostTests.Route) -> Bool {
        destination != .tabs
    }
}

private struct HostTestPage: View {
    let name: String
    let mode: String
    let recorder: HostTestRecorder
    @Environment(\.locale) private var locale

    var body: some View {
        _ = recorder.pages.append("\(name):\(mode):\(locale.identifier)")
        return Color.clear.frame(width: 10, height: 10)
    }
}

private struct HostTestConfiguredPage: View {
    @Environment(\.[navigation: NavigationHostTests.Key()]) private var configuration
    let isPresented: Bool

    var body: some View {
        NavigationConfiguredDestination(
            configuration: configuration, destination: .detail, isPresented: isPresented
        )
    }
}
