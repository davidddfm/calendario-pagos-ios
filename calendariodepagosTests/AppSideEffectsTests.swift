import Domain
import Features
import Synchronization
import Testing

@testable import calendariodepagos

/// §9.4: efectos secundarios de cada tipo de cambio.
@MainActor
@Suite("WID-03 · Recarga del widget")
struct AppSideEffectsTests {
    @Test(
        "Se recarga al cambiar pagos, su estado o el salario",
        arguments: [
            (DataChange.payments, 1),
            (.paymentStatus, 1),
            (.salary, 1),
            (.currency, 0),
            (.reminderSettings, 0),
        ])
    func reloadsWidgets(change: DataChange, expectedReloads: Int) {
        let tracker = DataChangeTracker()
        let widgets = SpyWidgetRefresher()
        let sideEffects = AppSideEffects(tracker: tracker, widgets: widgets)

        sideEffects.dataDidChange(change)

        #expect(widgets.reloadCount == expectedReloads)
        #expect(tracker.version == 1)
    }
}

private final class SpyWidgetRefresher: WidgetRefreshing {
    private let count = Mutex(0)

    var reloadCount: Int { count.withLock { $0 } }

    func reloadAll() { count.withLock { $0 += 1 } }
}
