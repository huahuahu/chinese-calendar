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
    func rejectedPublicSubmissionReleasesConfigurationAndClosureWithoutFinishing(hasExistingPage: Bool) {
        let router = Router(rootDestination: .home)
        let endpoint = NavigationPresentationEndpoint<Tab, Route, NoNavigationAlert>()
        endpoint.attach(context: router.rootPresentation, configuration: SubmissionTestConfiguration())
        let accepted = hasExistingPage ? router.rootPresentation.present(.sheet(.detail)) : nil
        weak var weakConfiguration: SubmissionTestConfiguration?
        weak var weakCapture: FinishCapture?
        var finishes = 0
        do {
            let configuration = SubmissionTestConfiguration()
            let capture = FinishCapture()
            weakConfiguration = configuration
            weakCapture = capture
            let rejected = router.rootPresentation.present(
                .sheet(.tabs), configuration: configuration, onFinish: {
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
        #expect(weakConfiguration == nil)
        #expect(weakCapture == nil)
        #expect(finishes == 0)
        #expect(router.rootLayer.queuedPresentations.isEmpty)
        if let accepted {
            #expect(router.presentedNode?.destination == .detail)
            #expect(accepted.handle?.dismiss() == .applied)
        } else {
            #expect(router.presentedNode == nil)
        }
        endpoint.detach()
        #expect(finishes == 0)
    }

    @MainActor
    private final class FinishCapture {
        var finished = false
    }
}

@MainActor
private final class SubmissionTestConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = NavigationSubmissionTests.Tab
    typealias Destination = NavigationSubmissionTests.Route
    typealias AlertRoute = NoNavigationAlert

    func destination(for destination: Destination) -> some View {
        Text(String(describing: destination))
    }
}
