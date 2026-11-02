import Observation

/// Las pantallas recargan con `.task(id: tracker.version)` cuando cambia cualquier dato (§9.4).
@Observable
public final class DataChangeTracker {
    public private(set) var version = 0

    public init() {}

    public func bump() { version &+= 1 }
}
