/// Estado de carga de una pantalla (§9.1).
public enum LoadState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(UserFacingError)

    public var value: Value? {
        if case .loaded(let value) = self { value } else { nil }
    }
}
