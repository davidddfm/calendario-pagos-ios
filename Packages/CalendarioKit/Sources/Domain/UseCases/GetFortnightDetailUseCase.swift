/// QUI-01 a QUI-04.
public struct GetFortnightDetailUseCase {
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let settings: any SettingsRepository
    private let clock: any DateProviding

    public init(
        payments: any PaymentRepository,
        records: any PaymentRecordRepository,
        settings: any SettingsRepository,
        clock: any DateProviding
    ) {
        self.payments = payments
        self.records = records
        self.settings = settings
        self.clock = clock
    }

    public func execute(_ fortnight: Fortnight) throws -> FortnightDetail {
        let period = YearMonth(containing: clock.now, calendar: clock.calendar)
        let statement = MonthStatementBuilder.build(
            period: period,
            payments: try payments.payments(includingDeleted: true),
            records: try records.records(in: period),
            calendar: clock.calendar
        )
        // Igual que Inicio: solo pagos vigentes.
        let items = statement.items(in: fortnight).filter(\.paymentExists)
        let total = items.map(\.displayAmount).sum()
        let remaining = settings.load().monthlySalary.map { $0.percent(50) - total }
        return FortnightDetail(fortnight: fortnight, period: period, items: items, total: total, remaining: remaining)
    }
}
