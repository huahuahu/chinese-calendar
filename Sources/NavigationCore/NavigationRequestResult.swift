/// Reports whether a navigation request was applied or deferred while presentations dismiss.
public enum NavigationRequestResult: Equatable, Sendable {
    case applied
    case deferredUntilPresentationDismisses
}
