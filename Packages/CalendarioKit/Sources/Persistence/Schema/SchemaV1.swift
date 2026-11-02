import Foundation
import SwiftData

/// Esquema publicado. Nunca se modifica: cualquier cambio crea `SchemaV2` y una etapa de migración (§7.1).
public enum SchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] { [PaymentEntity.self, PaymentRecordEntity.self] }

    @Model
    public final class PaymentEntity {
        #Unique<PaymentEntity>([\.id])
        #Index<PaymentEntity>([\.deletedAt], [\.dayOfMonth])

        public var id: UUID
        public var name: String
        public var amountMinorUnits: Int64
        public var dayOfMonth: Int
        /// Enum como `String`: predicados fiables.
        public var categoryRaw: String
        public var createdAt: Date
        public var updatedAt: Date
        public var deletedAt: Date?

        public init(
            id: UUID, name: String, amountMinorUnits: Int64, dayOfMonth: Int,
            categoryRaw: String, createdAt: Date, updatedAt: Date, deletedAt: Date?
        ) {
            self.id = id
            self.name = name
            self.amountMinorUnits = amountMinorUnits
            self.dayOfMonth = dayOfMonth
            self.categoryRaw = categoryRaw
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }
    }

    @Model
    public final class PaymentRecordEntity {
        /// Un solo registro por pago y mes.
        #Unique<PaymentRecordEntity>([\.id], [\.paymentID, \.periodKey])
        #Index<PaymentRecordEntity>([\.periodKey], [\.paymentID])

        public var id: UUID
        /// Referencia por valor, no relación (ADR-06).
        public var paymentID: UUID
        /// AAAAMM
        public var periodKey: Int
        public var name: String
        public var amountMinorUnits: Int64
        public var categoryRaw: String
        public var markedAt: Date

        public init(
            id: UUID, paymentID: UUID, periodKey: Int, name: String,
            amountMinorUnits: Int64, categoryRaw: String, markedAt: Date
        ) {
            self.id = id
            self.paymentID = paymentID
            self.periodKey = periodKey
            self.name = name
            self.amountMinorUnits = amountMinorUnits
            self.categoryRaw = categoryRaw
            self.markedAt = markedAt
        }
    }
}

public typealias PaymentEntity = SchemaV1.PaymentEntity
public typealias PaymentRecordEntity = SchemaV1.PaymentRecordEntity
