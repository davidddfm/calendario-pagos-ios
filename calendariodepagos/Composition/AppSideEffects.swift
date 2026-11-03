import Domain
import Features
import os

/// Centraliza los efectos de cualquier mutación (§9.4). Los widgets se agregan en la iteración 6.
final class AppSideEffects: DataChangeObserving {
    private let tracker: DataChangeTracker
    private var reconcile: (@MainActor () async throws -> Void)?
    /// Las reconciliaciones se encadenan: una ráfaga de cambios nunca deja un plan viejo al final.
    private var lastReconciliation: Task<Void, Never>?

    init(tracker: DataChangeTracker) {
        self.tracker = tracker
    }

    /// Se conecta después de crear el caso de uso, que no depende de este observador.
    func connect(reconcile: @escaping @MainActor () async throws -> Void) {
        self.reconcile = reconcile
    }

    func dataDidChange(_ change: DataChange) {
        tracker.bump()
        switch change {
        case .payments, .paymentStatus, .reminderSettings: reconcileReminders()  // NOT-02, NOT-05, NOT-08
        case .salary, .currency: break
        }
    }

    /// NOT-04: también al volver a la app, al cambiar el reloj y desde la tarea en segundo plano.
    @discardableResult
    func reconcileReminders() -> Task<Void, Never> {
        let previous = lastReconciliation
        let reconcile = reconcile
        // Los repositorios usan el `ModelContext` principal: la tarea debe quedarse en el `MainActor`.
        let task = Task { @MainActor in
            await previous?.value
            do {
                try await reconcile?()
            } catch {
                Logger(subsystem: "com.davidddfm.calendariodepagos", category: "reminders")
                    .error(
                        "No se pudieron programar los avisos: \(String(describing: type(of: error)), privacy: .public)")
            }
        }
        lastReconciliation = task
        return task
    }
}
