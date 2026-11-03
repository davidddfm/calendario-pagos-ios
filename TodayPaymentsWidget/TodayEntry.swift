import Domain
import Foundation
import Persistence
import SwiftData
import WidgetKit
import os

/// WID-01 (§10.3): la entrada solo lleva nombres y estados; ninguna vista puede mostrar dinero.
/// WID-06: tampoco consulta el bloqueo de la app.
nonisolated struct TodayEntry: TimelineEntry {
    let date: Date
    let content: Content

    enum Content {
        case snapshot(TodaySnapshot)
        /// No se pudo leer el almacén (§7.2): "Abre la app para ver tus pagos".
        case unavailable
    }
}

nonisolated extension TodayEntry {
    /// Nunca lanza: si la lectura falla, la entrada indica que hay que abrir la app.
    static func load(for dates: [Date], calendar: Calendar) -> [TodayEntry] {
        do {
            let container = try PersistenceStack.makeContainer()
            let context = ModelContext(container)
            let useCase = GetTodayWidgetSnapshotUseCase(
                payments: SwiftDataPaymentRepository(context: context),
                records: SwiftDataPaymentRecordRepository(context: context),
                calendar: calendar)
            return try withExtendedLifetime(container) {
                try dates.map { TodayEntry(date: $0, content: .snapshot(try useCase.execute(for: $0))) }
            }
        } catch {
            Logger(subsystem: "com.davidddfm.calendariodepagos", category: "widget")
                .error("No se pudo leer el almacén: \(String(describing: type(of: error)), privacy: .public)")
            return []
        }
    }

    /// Galería y marcador de posición: datos de ejemplo, sin montos.
    static func sample(date: Date) -> TodayEntry {
        TodayEntry(
            date: date,
            content: .snapshot(
                TodaySnapshot(
                    date: date,
                    items: [
                        .init(id: UUID(), name: String(localized: "Renta"), isPaid: true),
                        .init(id: UUID(), name: String(localized: "Internet"), isPaid: false),
                        .init(id: UUID(), name: String(localized: "Gimnasio"), isPaid: false),
                    ])))
    }
}
