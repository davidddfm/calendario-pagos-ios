import Foundation

/// CAL-01, CAL-02, PAG-07.
public struct GetCalendarMonthUseCase {
    private let source: CalendarStatementSource

    public init(payments: any PaymentRepository, records: any PaymentRecordRepository, clock: any DateProviding) {
        source = CalendarStatementSource(payments: payments, records: records, clock: clock)
    }

    /// Mes con el que abre el Calendario.
    public var currentPeriod: YearMonth { source.currentPeriod }

    public func execute(_ period: YearMonth) throws -> CalendarMonth {
        let calendar = source.clock.calendar
        guard let startDate = period.date(day: 1, calendar: calendar) else { throw DomainError.invalidDate }
        let statement = try source.statement(for: period)

        let days = try (1...period.numberOfDays).map { day in
            guard let date = period.date(day: day, calendar: calendar) else { throw DomainError.invalidDate }
            let items = statement.items(onEffectiveDay: day)
            return CalendarMonth.Day(
                day: day, date: date, count: items.count, paidCount: items.count(where: \.isPaid),
                total: items.map(\.displayAmount).sum())
        }

        // `weekday` va de 1 (domingo) a 7; `firstWeekday` depende de la región.
        let firstWeekday = calendar.firstWeekday
        let leading = (calendar.component(.weekday, from: startDate) - firstWeekday + 7) % 7
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let rotated = Array(symbols[(firstWeekday - 1)...] + symbols[..<(firstWeekday - 1)])

        return CalendarMonth(
            period: period,
            startDate: startDate,
            leadingEmptyDays: leading,
            weekdaySymbols: rotated,
            days: days,
            today: period == source.currentPeriod ? calendar.component(.day, from: source.clock.now) : nil,
            total: statement.total
        )
    }
}
