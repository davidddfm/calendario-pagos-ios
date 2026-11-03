import Foundation

/// CAL-03 a CAL-05, PAG-07.
public struct GetDayDetailUseCase {
    private let source: CalendarStatementSource

    public init(payments: any PaymentRepository, records: any PaymentRecordRepository, clock: any DateProviding) {
        source = CalendarStatementSource(payments: payments, records: records, clock: clock)
    }

    public func execute(_ date: Date) throws -> DayDetail {
        let calendar = source.clock.calendar
        let period = YearMonth(containing: date, calendar: calendar)
        let day = calendar.component(.day, from: date)
        return DayDetail(
            date: date,
            period: period,
            items: try source.statement(for: period).items(onEffectiveDay: day),
            isEditable: period == source.currentPeriod
        )
    }
}
