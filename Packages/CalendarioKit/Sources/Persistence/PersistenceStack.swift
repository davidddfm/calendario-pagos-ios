import Foundation
import SwiftData
import os

/// Contenedor compartido con la extensión de widgets mediante el App Group (§7.2).
public enum PersistenceStack {
    public static let appGroupID = "group.com.davidddfm.calendariodepagos"

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration = ModelConfiguration(
            "CalendarioDePagos",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            groupContainer: inMemory ? .none : .identifier(appGroupID),
            cloudKitDatabase: .none  // 100 % local: nunca sincroniza aunque exista el entitlement
        )
        do {
            return try ModelContainer(
                for: schema, migrationPlan: CalendarioMigrationPlan.self, configurations: [configuration])
        } catch {
            Logger.persistence.error(
                "No se pudo abrir el almacén: \(String(describing: type(of: error)), privacy: .public) \(error, privacy: .private)"
            )
            throw PersistenceError.storeUnavailable
        }
    }

    /// Preferencias del App Group (§7.4). `nil` solo si el identificador no es válido.
    public static func makeSharedDefaults() -> UserDefaults? {
        UserDefaults(suiteName: appGroupID)
    }
}
