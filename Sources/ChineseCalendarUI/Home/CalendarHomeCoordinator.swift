import ChineseCalendarLocalization
import Foundation
import Observation
import SwiftData

/// 协调页面入口和呈现上下文；导航结构由 Router 保存，业务状态仍属于对应 feature。
@MainActor
@Observable
final class CalendarHomeCoordinator {
    let router: CalendarRouter
    var alertMessages: [UUID: LocalizedStringResource] = [:]
    private(set) var yearPickerSessions: [UUID: CalendarYearPickerSession] = [:]
    private var didOpenColdLaunchDeepLink = false
    private var storeIdentity: String?
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
        #if DEBUG
            downloadPreviewSessions = downloadPreviewSessions.filter {
                destinations.contains(.downloadPreview(sessionID: $0.key))
            }
            debugSplitStates = debugSplitStates.filter(\.value.navigation.isActive)
        #endif
    }

    #if DEBUG
        /// 选择与布局跟随实际详情栈，数据页面重建时仍与原路径保持一致。
        func debugSplitState(for navigation: CalendarNavigationContext) -> CalendarDebugSplitState {
            let identity = ObjectIdentifier(navigation)
            // 关闭动画中的旧页面仍读取原状态，待宿主完成关闭后再统一释放。
            if let session = debugSplitStates[identity] { return session.state }
            let state = CalendarDebugSplitState()
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
