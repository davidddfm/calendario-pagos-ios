/// PAG-05 a PAG-08: construye Inicio a partir del estado del mes actual.
public struct GetHomeSummaryUseCase {
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let clock: any DateProviding

    public init(payments: any PaymentRepository, records: any PaymentRecordRepository, clock: any DateProviding) {
        self.payments = payments
        self.records = records
        self.clock = clock
    }

    public func execute() throws -> HomeSummary {
        let now = clock.now
        let calendar = clock.calendar
        let period = YearMonth(containing: now, calendar: calendar)
        let statement = MonthStatementBuilder.build(
            period: period,
            payments: try payments.payments(includingDeleted: true),
            records: try records.records(in: period),
            calendar: calendar
        )
        let today = calendar.component(.day, from: now)
        // Inicio muestra solo pagos vigentes; los eliminados después de pagarlos quedan en el Historial.
        let items = statement.items.filter(\.paymentExists)

        return HomeSummary(
            today: now,
            todayItems: items.filter { $0.effectiveDay == today },
            fortnights: Fortnight.allCases.map { fortnight in
                let inFortnight = items.filter { $0.fortnight == fortnight }
                return HomeSummary.FortnightTotal(
                    fortnight: fortnight, total: inFortnight.map(\.displayAmount).sum(), count: inFortnight.count)
            },
            allItems: items
        )
    }
}
