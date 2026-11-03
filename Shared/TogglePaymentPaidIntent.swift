import AppIntents
import Domain
import Foundation
import Persistence
import SwiftData
import SystemServices
import os

/// WID-07 (§10.4): casilla del widget. Pertenece a los targets App y Widget.
struct TogglePaymentPaidIntent: AppIntent {
    static let title: LocalizedStringResource = "Marcar pago"
    /// Sin integración con Siri ni Atajos (§12 de la especificación).
    static let isDiscoverable = false

    @Parameter(title: "Pago") var paymentID: String

    init() {}

    init(paymentID: UUID) {
        self.paymentID = paymentID.uuidString
    }

    /// Solo acepta el `UUID` de un pago existente y nunca borra datos (§14.5). Si falla, WidgetKit mantiene el
    /// estado anterior; tras ejecutarla, recarga la línea de tiempo.
    func perform() async throws -> some IntentResult {
        guard let id = UUID(uuidString: paymentID) else { return .result() }
        let container = try PersistenceStack.makeContainer()
        let context = ModelContext(container)
        let payments = SwiftDataPaymentRepository(context: context)
        let records = SwiftDataPaymentRecordRepository(context: context)
        let clock = SystemClock()
        try TogglePaymentPaidUseCase(
            payments: payments, records: records, clock: clock, observer: IntentChangeObserver()
        ).execute(paymentID: id)

        // NOT-08 también desde el widget (R-02). Si falla, la app reconcilia al volver a `.active`.
        guard let defaults = PersistenceStack.makeSharedDefaults() else { return .result() }
        let settings = UserDefaultsSettingsRepository(defaults: defaults, hasStoredPayments: { true })
        do {
            try await RescheduleRemindersUseCase(
                payments: payments, records: records, settings: settings,
                scheduler: UserNotificationReminderScheduler(route: DeepLink.today.rawValue), clock: clock
            ).execute()
        } catch {
            Logger(subsystem: "com.davidddfm.calendariodepagos", category: "widget")
                .error("No se pudieron programar los avisos: \(String(describing: type(of: error)), privacy: .public)")
        }
        withExtendedLifetime(container) {}
        return .result()
    }
}

/// En la extensión no hay pantallas que avisar; los avisos se reprograman al terminar la intención.
nonisolated private struct IntentChangeObserver: DataChangeObserving {
    func dataDidChange(_ change: DataChange) {}
}
