/// Describes a navigation change without attaching URL parsing or domain-specific routing rules.
public enum NavigationRequest<Scope: Hashable, Destination: Hashable>: Hashable {
    case selectScope(Scope)
    case setRoot(Destination?, on: Scope)
    case replacePath([Destination], on: Scope)
    case push(Destination, on: Scope)
}
