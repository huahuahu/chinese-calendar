@testable import NavigationCore
import SwiftUI
import Testing

@MainActor
@Suite("拒绝呈现的资源回滚")
struct NavigationSubmissionTests {
    fileprivate enum Tab: NavigationScope { case home }
    fileprivate enum Route: NavigationDestination {
        case home, detail, tabs

        var providesNavigationContainer: Bool {
            self == .tabs
        }
    }

    private typealias Router = NavigationRouter<Tab, Route, NoNavigationAlert>

    @Test(arguments: [false, true])
    func rejectedPublicSubmissionReleasesClosureWithoutDismissal(hasExistingPage: Bool) {
        let router = Router(rootDestination: .home)
        let accepted = hasExistingPage ? router.rootPresentation.present(.sheet(.detail)) : nil
        weak var weakCapture: FinishCapture?
        var finishes = 0
        do {
            let capture = FinishCapture()
            weakCapture = capture
            let rejected = router.rootPresentation.present(
                .sheet(.tabs), onDismiss: {
                    capture.finished = true
                    finishes += 1
                }
            )
            let reason: NavigationRejectionReason = hasExistingPage ? .presentationAlreadyExists :
                .missingRootDestination
            #expect(rejected.result == .rejected(reason))
            #expect(rejected.handle == nil)
            #expect(!capture.finished)
        }
        #expect(weakCapture == nil)
        #expect(finishes == 0)
        #expect(router.rootLayer.queuedPresentations.isEmpty)
        if let accepted {
            #expect(router.presentedNode?.destination == .detail)
            #expect(accepted.handle?.dismiss() == .applied)
        } else {
            #expect(router.presentedNode == nil)
        }
        #expect(finishes == 0)
    }

    @MainActor
    private final class FinishCapture {
        var finished = false
    }
}
