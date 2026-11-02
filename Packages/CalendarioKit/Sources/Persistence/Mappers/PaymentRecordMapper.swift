import Domain
import os

enum PaymentRecordMapper {
    static func toDomain(_ entity: PaymentRecordEntity) -> PaymentRecord? {
        guard let period = YearMonth(key: entity.periodKey) else {
            Logger.persistence.error("Registro omitido: periodo \(entity.periodKey, privacy: .public) inválido")
            return nil
        }
        // Un registro con monto inválido conserva el resto de la instantánea con monto cero: el pago sí se marcó.
        let amount =
            (0...Money.maxInputMinorUnits).contains(entity.amountMinorUnits)
            ? Money(minorUnits: entity.amountMinorUnits) : .zero
        return PaymentRecord(
            id: entity.id,
            paymentID: entity.paymentID,
            period: period,
            name: PaymentMapper.displayName(entity.name),
            amount: amount,
            category: PaymentCategory(storedValue: entity.categoryRaw),
            markedAt: entity.markedAt
        )
    }

    static func makeEntity(from record: PaymentRecord) -> PaymentRecordEntity {
        PaymentRecordEntity(
            id: record.id,
            paymentID: record.paymentID,
            periodKey: record.period.key,
            name: record.name,
            amountMinorUnits: record.amount.minorUnits,
            categoryRaw: record.category.rawValue,
            markedAt: record.markedAt
        )
    }
}
