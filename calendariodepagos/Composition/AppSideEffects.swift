import Domain
import Features

/// Centraliza los efectos de cualquier mutación (§9.4). Widgets y avisos se agregan en las iteraciones 5 y 6.
final class AppSideEffects: DataChangeObserving {
    private let tracker: DataChangeTracker

    init(tracker: DataChangeTracker) {
        self.tracker = tracker
    }

    func dataDidChange(_ change: DataChange) {
        tracker.bump()
    }
}
