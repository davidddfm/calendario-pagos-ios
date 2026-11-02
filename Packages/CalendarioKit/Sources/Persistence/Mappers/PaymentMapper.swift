import Domain
import Foundation
import os

/// El almacén es entrada no confiable (§7.5): lo inválido se omite y se registra, nunca cierra la app.
enum PaymentMapper {
    static func toDomain(_ entity: PaymentEntity) -> Payment? {
        guard PaymentValidator.validDays.contains(entity.dayOfMonth) else {
            Logger.persistence.error("Pago omitido: día \(entity.dayOfMonth, privacy: .public) fuera de rango")
            return nil
        }
        guard entity.amountMinorUnits > 0, entity.amountMinorUnits <= Money.maxInputMinorUnits else {
            Logger.persistence.error("Pago omitido: monto fuera de rango")
            return nil
        }
        return Payment(
            id: entity.id,
            name: displayName(entity.name),
            amount: Money(minorUnits: entity.amountMinorUnits),
            dayOfMonth: entity.dayOfMonth,
            category: PaymentCategory(storedValue: entity.categoryRaw),
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            deletedAt: entity.deletedAt
        )
    }

    static func makeEntity(from payment: Payment) -> PaymentEntity {
        PaymentEntity(
            id: payment.id,
            name: payment.name,
            amountMinorUnits: payment.amount.minorUnits,
            dayOfMonth: payment.dayOfMonth,
            categoryRaw: payment.category.rawValue,
            createdAt: payment.createdAt,
            updatedAt: payment.updatedAt,
            deletedAt: payment.deletedAt
        )
    }

    static func apply(_ payment: Payment, to entity: PaymentEntity) {
        entity.name = payment.name
        entity.amountMinorUnits = payment.amount.minorUnits
        entity.dayOfMonth = payment.dayOfMonth
        entity.categoryRaw = payment.category.rawValue
        entity.updatedAt = payment.updatedAt
        entity.deletedAt = payment.deletedAt
    }

    static func displayName(_ stored: String) -> String {
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? String(localized: "Sin nombre", bundle: .module) : stored
    }
}
