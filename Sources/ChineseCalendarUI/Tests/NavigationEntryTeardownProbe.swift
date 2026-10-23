import NavigationCore
import SwiftUI
import UIKit

/// 从 destination 自己的 UIKit 生命周期拆除宿主，观察真实入场与离窗，不驱动 Core completion。
@MainActor
final class NavigationEntryTeardownProbe {
    var onEntry: (() -> Void)?
    private weak var presentedController: UIViewController?
    private weak var contentController: UIViewController?
    private(set) var didTrigger = false
    private(set) var hadPresenterAtEntry = false
    private(set) var wasBeingPresentedAtEntry = false
    private(set) var finishes = 0
    private(set) var finishedAfterPhysicalDismissal = false
    private(set) var attachedAfterFinish = false

    func willAppear(_ controller: UIViewController) {
        guard !didTrigger else { return }
        didTrigger = true
        contentController = controller
        var modal = controller
        while let parent = modal.parent {
            modal = parent
        }
        presentedController = modal
        hadPresenterAtEntry = modal.presentingViewController != nil
        wasBeingPresentedAtEntry = modal.isBeingPresented
        let action = onEntry
        onEntry = nil
        action?()
    }

    func windowChanged(_ window: UIWindow?) {
        if window != nil, finishes > 0 { attachedAfterFinish = true }
    }

    func recordFinish() {
        finishes += 1
        finishedAfterPhysicalDismissal = didTrigger &&
            presentedController?.presentingViewController == nil &&
            presentedController?.viewIfLoaded?.window == nil &&
            presentedController?.isBeingPresented != true &&
            presentedController?.isBeingDismissed != true &&
            contentController?.viewIfLoaded?.window == nil
    }
}

@MainActor
final class NavigationEntryTeardownConfiguration: @MainActor NavigationHostConfiguration {
    typealias Scope = NavigationPhysicalHostTests.Scope
    typealias Destination = NavigationPhysicalHostTests.Destination
    typealias AlertRoute = NavigationPhysicalHostTests.Notice

    let probe: NavigationEntryTeardownProbe
    let resource: PhysicalHostResource

    init(probe: NavigationEntryTeardownProbe, resource: PhysicalHostResource) {
        self.probe = probe
        self.resource = resource
    }

    func destination(for _: Destination) -> some View {
        NavigationEntryProbeContent(probe: probe)
    }
}

private struct NavigationEntryProbeContent: UIViewControllerRepresentable {
    let probe: NavigationEntryTeardownProbe

    func makeUIViewController(context: Context) -> NavigationEntryProbeController {
        NavigationEntryProbeController(probe: probe)
    }

    func updateUIViewController(_ controller: NavigationEntryProbeController, context: Context) {}
}

private final class NavigationEntryProbeController: UIViewController {
    private weak var probe: NavigationEntryTeardownProbe?

    init(probe: NavigationEntryTeardownProbe) {
        self.probe = probe
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = NavigationEntryProbeView(probe: probe)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        probe?.willAppear(self)
    }
}

private final class NavigationEntryProbeView: UIView {
    private weak var probe: NavigationEntryTeardownProbe?

    init(probe: NavigationEntryTeardownProbe?) {
        self.probe = probe
        super.init(frame: .zero)
        backgroundColor = .systemBackground
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        probe?.windowChanged(window)
    }
}
