import Domain
import Foundation
import SwiftData

public final class SwiftDataPaymentRecordRepository: PaymentRecordRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func records(in period: YearMonth) throws -> [PaymentRecord] {
        let key = period.key
        return try context.fetchOrThrow(
            FetchDescriptor<PaymentRecordEntity>(predicate: #Predicate { $0.periodKey == key })
        )
        .compactMap(PaymentRecordMapper.toDomain)
    }

    public func records(from start: YearMonth, through end: YearMonth) throws -> [PaymentRecord] {
        let startKey = start.key
        let endKey = end.key
        let descriptor = FetchDescriptor<PaymentRecordEntity>(
            predicate: #Predicate { $0.periodKey >= startKey && $0.periodKey <= endKey })
        return try context.fetchOrThrow(descriptor).compactMap(PaymentRecordMapper.toDomain)
    }

    public func record(paymentID: UUID, period: YearMonth) throws -> PaymentRecord? {
        try entities(paymentID: paymentID, period: period).first.flatMap(PaymentRecordMapper.toDomain)
    }

    /// Idempotente: si ya hay un registro del pago en el mes, se reemplaza su instantánea (doble toque, app ↔ widget).
    public func insert(_ record: PaymentRecord) throws {
        if let existing = try entities(paymentID: record.paymentID, period: record.period).first {
            existing.name = record.name
            existing.amountMinorUnits = record.amount.minorUnits
            existing.categoryRaw = record.category.rawValue
            existing.markedAt = record.markedAt
        } else {
            context.insert(PaymentRecordMapper.makeEntity(from: record))
        }
        try context.saveOrThrow()
    }

    public func delete(paymentID: UUID, period: YearMonth) throws {
        for entity in try entities(paymentID: paymentID, period: period) {
            context.delete(entity)
        }
        try context.saveOrThrow()
    }

    private func entities(paymentID: UUID, period: YearMonth) throws -> [PaymentRecordEntity] {
        let key = period.key
        return try context.fetchOrThrow(
            FetchDescriptor<PaymentRecordEntity>(
                predicate: #Predicate { $0.paymentID == paymentID && $0.periodKey == key }))
    }
}
