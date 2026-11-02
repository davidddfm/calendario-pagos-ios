import SwiftData
import os

extension ModelContext {
    /// Lectura con el error de SwiftData envuelto y registrado (§14.3).
    func fetchOrThrow<T: PersistentModel>(_ descriptor: FetchDescriptor<T>) throws -> [T] {
        do {
            return try fetch(descriptor)
        } catch {
            Logger.persistence.error(
                "Fallo al leer: \(String(describing: type(of: error)), privacy: .public) \(error, privacy: .private)")
            throw PersistenceError.fetchFailed
        }
    }

    /// Guardado explícito tras cada escritura para que el widget vea el cambio de inmediato (§7.5).
    func saveOrThrow() throws {
        do {
            try save()
        } catch {
            rollback()
            Logger.persistence.error(
                "Fallo al guardar: \(String(describing: type(of: error)), privacy: .public) \(error, privacy: .private)"
            )
            throw PersistenceError.saveFailed
        }
    }
}
