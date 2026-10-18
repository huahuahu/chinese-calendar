@testable import ChineseCalendarUI
import Testing

@MainActor
@Test func manualDismissalDefersTheLatestDeepLinkUntilTheHostFinishes() {
    let router = CalendarRouter(yearsPath: [.lunarYear(2024)])
    router.presentSheet(.lunarYear(2025))
    router.dismissSheet()

    #expect(router.isAwaitingPresentationDismissal)
    #expect(router.openDeepLink(.lunarYear(2026, monthIndex: nil)) == .deferredUntilPresentationDismisses)
    #expect(router.openDeepLink(.emperor("ming-taizu")) == .deferredUntilPresentationDismisses)
    // 手动关闭和深链接主动关闭统一由 Core 等待最新请求。
    #expect(router.navigation.deferredRequest == .replacePath([.emperor("ming-taizu")], on: .history))
    router.presentFullScreen(.downloadDetails)
    #expect(!router.hasActivePresentation)
    #expect(router.yearsPath == [.lunarYear(2024)])
    #expect(router.historyPath.isEmpty)

    router.rootPresentationDidDismiss()
    #expect(router.historyPath == [.emperor("ming-taizu")])
    #expect(!router.isAwaitingPresentationDismissal)
    router.rootPresentationDidDismiss()
    #expect(router.historyPath == [.emperor("ming-taizu")])
}

@MainActor
@Test func dismissalWithoutARequestAllowsReopening() {
    let router = CalendarRouter()
    router.presentFullScreen(.downloadDetails)
    let originalID = router.fullScreen?.id
    router.dismissFullScreen()
    #expect(router.isAwaitingPresentationDismissal)

    router.rootPresentationDidDismiss()
    router.presentFullScreen(.downloadDetails)
    #expect(router.fullScreen != nil)
    #expect(router.fullScreen?.id != originalID)
}

@MainActor
@Test func targetedDismissalPreservesTheParentAndTabPaths() throws {
    let router = CalendarRouter()
    router.push(.lunarYear(2024))
    router.presentFullScreen(.lunarYear(2025))
    let parent = try #require(router.fullScreen)
    router.navigation.context(for: parent).push(.lunarYear(2026))
    router.navigation.presentationContext(for: parent).present(.downloadDetails)
    let child = try #require(parent.sheet)
    router.navigation.presentationContext(for: child).present(.lunarYear(2027), style: .fullScreen)
    #expect(router.presentations.count == 3)

    #expect(router.dismissPresentation(id: child.id))
    #expect(router.fullScreen === parent)
    #expect(parent.sheet == nil)
    #expect(parent.path == [.lunarYear(2026)])
    #expect(router.yearsPath == [.lunarYear(2024)])
    #expect(!router.isAwaitingPresentationDismissal)
    #expect(!router.dismissPresentation(id: child.id))
}
