/// HIS-03 / HIS-04: pagos de un mes separados en pagados y pendientes.
public struct GetMonthStatementUseCase {
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let clock: any DateProviding

    public init(payments: any PaymentRepository, records: any PaymentRecordRepository, clock: any DateProviding) {
        self.payments = payments
        self.records = records
        self.clock = clock
    }

    public func execute(_ period: YearMonth) throws -> MonthStatement {
        MonthStatementBuilder.build(
            period: period,
            payments: try payments.payments(includingDeleted: true),
            records: try records.records(in: period),
            calendar: clock.calendar
        )
    }
}
