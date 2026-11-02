import Foundation

public protocol PaymentRecordRepository {
    func records(in period: YearMonth) throws -> [PaymentRecord]
    func records(from start: YearMonth, through end: YearMonth) throws -> [PaymentRecord]
    func record(paymentID: UUID, period: YearMonth) throws -> PaymentRecord?
    /// Idempotente: un segundo registro del mismo pago y mes reemplaza al primero (§7.5).
    func insert(_ record: PaymentRecord) throws
    func delete(paymentID: UUID, period: YearMonth) throws
}
