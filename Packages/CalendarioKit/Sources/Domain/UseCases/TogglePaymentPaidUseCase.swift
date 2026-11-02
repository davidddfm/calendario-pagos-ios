import Foundation

/// MAR-01 a MAR-04, HIS-04: marca o desmarca un pago en un mes. Al marcar guarda la instantánea del pago.
public struct TogglePaymentPaidUseCase {
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let clock: any DateProviding
    private let observer: any DataChangeObserving

    public init(
        payments: any PaymentRepository,
        records: any PaymentRecordRepository,
        clock: any DateProviding,
        observer: any DataChangeObserving
    ) {
        self.payments = payments
        self.records = records
        self.clock = clock
        self.observer = observer
    }

    /// Marca o desmarca un pago en `period` (por defecto, el mes actual). Devuelve el nuevo estado.
    @discardableResult
    public func execute(paymentID: UUID, period: YearMonth? = nil) throws -> Bool {
        let current = YearMonth(containing: clock.now, calendar: clock.calendar)
        let period = period ?? current
        guard period <= current else { throw DomainError.futurePeriod }

        if try records.record(paymentID: paymentID, period: period) != nil {
            try records.delete(paymentID: paymentID, period: period)
            observer.dataDidChange(.paymentStatus)
            return false
        }

        guard let payment = try payments.payment(id: paymentID) else { throw DomainError.paymentNotFound }
        guard payment.isActive(in: period, calendar: clock.calendar) else { throw DomainError.paymentNotInPeriod }

        try records.insert(PaymentRecord(snapshotOf: payment, period: period, markedAt: clock.now))  // MAR-04
        observer.dataDidChange(.paymentStatus)
        return true
    }
}
