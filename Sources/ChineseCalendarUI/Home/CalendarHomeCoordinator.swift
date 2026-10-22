import ChineseCalendarLocalization
import Foundation
import Observation
import SwiftData

/// 把 Deep Link、年份选择和下载相关动作交给 Router，并保存这些流程所需的临时业务数据。
/// 例如年份选择会话保存发起页的 CalendarSelection、ModelContext 和回调；模态与路径仍由 Router 保存。
@MainActor
@Observable
final class CalendarHomeCoordinator {
    let router: CalendarRouter
    var alertMessages: [UUID: LocalizedStringResource] = [:]
    private(set) var yearPickerSessions: [UUID: CalendarYearPickerSession] = [:]
    private var didOpenColdLaunchDeepLink = false
    private var storeIdentity: String?
    @ObservationIgnored private var historyStates: [
        ObjectIdentifier: (navigation: CalendarNavigationContext, state: CalendarHistoryState)
    ] = [:]
    #if DEBUG
        private(set) var downloadPreviewSessions: [UUID: FullStoreDownloadPreviewState] = [:]
        @ObservationIgnored private var debugSplitStates: [
            ObjectIdentifier: (navigation: CalendarNavigationContext, state: CalendarDebugSplitState)
        ] = [:]
    #endif

    init(router: CalendarRouter = CalendarRouter()) {
        self.router = router
    }

    func openDeepLink(_ deepLink: CalendarDeepLink) {
        _ = router.openDeepLink(deepLink, confirmIfPresented: true)
    }

    func openColdLaunchDeepLink(_ deepLink: CalendarDeepLink?) {
        guard !didOpenColdLaunchDeepLink else { return }
        didOpenColdLaunchDeepLink = true
        _ = router.openColdLaunchDeepLink(deepLink)
    }

    func presentYearPicker(
        selection: CalendarSelection,
        modelContext: ModelContext,
        presentation: CalendarPresentationContext? = nil,
        selectYear: @escaping (Int) -> Void
    ) {
        guard !router.isAwaitingPresentationDismissal,
              !yearPickerSessions.values.contains(where: {
                  $0.selection === selection && $0.modelContext === modelContext
              })
        else { return }
        let session = CalendarYearPickerSession(
            selection: selection, modelContext: modelContext, selectYear: selectYear
        )
        yearPickerSessions[session.id] = session
        if let presentation {
            if !presentation.present(.yearPicker(sessionID: session.id)) { yearPickerSessions[session.id] = nil }
        } else {
            router.presentSheet(.yearPicker(sessionID: session.id))
        }
    }

    func selectYear(_ yearNumber: Int, sessionID: UUID) {
        guard let session = yearPickerSessions[sessionID],
              dismissPresentation(.yearPicker(sessionID: sessionID))
        else { return }
        session.selectYear(yearNumber)
    }

    func presentDownloadDetails() {
        guard !router.presentations.contains(where: { $0.destination == .downloadDetails }) else { return }
        router.presentSheet(.downloadDetails)
    }

    func downloadProgressDidDisappear() {
        dismissPresentation(.downloadDetails)
    }

    @discardableResult
    func dismissPresentation(_ destination: CalendarDestination) -> Bool {
        guard let node = router.presentations.first(where: { $0.destination == destination }) else {
            return false
        }
        return router.dismissPresentation(id: node.id)
    }

    func storeIdentityDidChange(_ identity: String?) {
        guard storeIdentity != identity else { return }
        storeIdentity = identity
        for sessionID in yearPickerSessions.keys {
            dismissPresentation(.yearPicker(sessionID: sessionID))
        }
        // 旧 ModelContext 不再参与页面构建或选择回传。
        yearPickerSessions.removeAll()
    }

    func rootPresentationDidDismiss() {
        router.rootPresentationDidDismiss()
        releaseDismissedContexts()
    }

    func releaseDismissedContexts() {
        let messageIDs = Set(router.navigation.alertRoutes.compactMap(\.messageID))
        alertMessages = alertMessages.filter { messageIDs.contains($0.key) }
        let destinations = Set(router.presentations.map(\.destination))
        yearPickerSessions = yearPickerSessions.filter { destinations.contains(.yearPicker(sessionID: $0.key)) }
        historyStates = historyStates.filter(\.value.navigation.isActive)
        #if DEBUG
            downloadPreviewSessions = downloadPreviewSessions.filter {
                destinations.contains(.downloadPreview(sessionID: $0.key))
            }
            debugSplitStates = debugSplitStates.filter(\.value.navigation.isActive)
        #endif
    }

    /// 按详情栈身份保留历史栏布局；同名栈在不同模态中仍拥有独立状态。
    func historyState(for navigation: CalendarNavigationContext) -> CalendarHistoryState {
        let identity = ObjectIdentifier(navigation)
        if let session = historyStates[identity] { return session.state }
        let state = CalendarHistoryState(navigation: navigation)
        if navigation.isActive { historyStates[identity] = (navigation, state) }
        return state
    }

    #if DEBUG
        /// 按详情栈 Context 的对象身份复用分栏选择和布局，避免页面重建后只剩旧 path、丢失详情选择。
        /// 新打开的模态即使使用同名栈，也会得到独立的分栏状态。
        func debugSplitState(for navigation: CalendarNavigationContext) -> CalendarDebugSplitState {
            let identity = ObjectIdentifier(navigation)
            // 关闭动画中的旧页面仍读取原状态，待宿主完成关闭后再统一释放。
            if let session = debugSplitStates[identity] { return session.state }
            let state = CalendarDebugSplitState(navigation: navigation)
            if navigation.isActive { debugSplitStates[identity] = (navigation, state) }
            return state
        }

        func presentDownloadPreview(presentation: CalendarPresentationContext? = nil) {
            guard !router.isAwaitingPresentationDismissal, downloadPreviewSessions.isEmpty else { return }
            let session = FullStoreDownloadPreviewState()
            downloadPreviewSessions[session.id] = session
            let entry = presentation ?? router.navigation.frontmostPresentationNode.map {
                router.navigation.presentationContext(for: $0)
            } ?? router.navigation.rootPresentation
            if !entry.present(
                .downloadPreview(sessionID: session.id), style: .fullScreen, initialStack: .scope(.years),
                rootDestinations: [
                    .scope(.years): .downloadPreviewScenarios(sessionID: session.id),
                    .scope(.history): .downloadPreviewSwitch
                ]
            ) {
                downloadPreviewSessions[session.id] = nil
            }
        }

        func presentDownloadPreviewDetails(sessionID: UUID) {
            guard let parent = router.presentations.first(where: {
                $0.destination == .downloadPreview(sessionID: sessionID)
            }), parent.sheet == nil else { return }
            router.navigation.presentationContext(for: parent).present(.downloadPreviewDetails(sessionID: sessionID))
        }
    #endif
}
