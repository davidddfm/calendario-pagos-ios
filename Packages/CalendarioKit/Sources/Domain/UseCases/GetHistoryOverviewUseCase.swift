/// HIS-01, HIS-02 y supuesto S-04.
public struct GetHistoryOverviewUseCase {
    public static let chartMonths = 6

    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let clock: any DateProviding

    public init(payments: any PaymentRepository, records: any PaymentRecordRepository, clock: any DateProviding) {
        self.payments = payments
        self.records = records
        self.clock = clock
    }

    public func execute() throws -> HistoryOverview {
        let calendar = clock.calendar
        let current = YearMonth(containing: clock.now, calendar: calendar)
        let allPayments = try payments.payments(includingDeleted: true)
        let chartStart = current.adding(months: -(Self.chartMonths - 1))

        guard let oldest = allPayments.map({ YearMonth(containing: $0.createdAt, calendar: calendar) }).min(),
            oldest <= current
        else {
            return HistoryOverview(months: [], chart: [])
        }

        let firstMonth = min(oldest, chartStart)
        let recordsByPeriod = Dictionary(
            grouping: try records.records(from: firstMonth, through: current), by: \.period)

        func summary(_ period: YearMonth) -> HistoryOverview.MonthSummary? {
            guard let startDate = period.date(day: 1, calendar: calendar) else { return nil }
            let statement = MonthStatementBuilder.build(
                period: period, payments: allPayments, records: recordsByPeriod[period] ?? [], calendar: calendar)
            return HistoryOverview.MonthSummary(
                period: period,
                startDate: startDate,
                paidTotal: statement.paidTotal,
                paidCount: statement.paid.count,
                totalCount: statement.items.count
            )
        }

        var months: [HistoryOverview.MonthSummary] = []
        var period = current
        while period >= oldest {
            if let month = summary(period) { months.append(month) }
            period = period.adding(months: -1)
        }
        let chart = (0..<Self.chartMonths).compactMap { summary(chartStart.adding(months: $0)) }
        return HistoryOverview(months: months, chart: chart)
    }
}
