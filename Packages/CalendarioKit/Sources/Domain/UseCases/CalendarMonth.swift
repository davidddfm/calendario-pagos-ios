import Foundation

/// Cuadrícula de un mes del Calendario (CAL-01, CAL-02, PAG-07).
public struct CalendarMonth: Sendable {
    public let period: YearMonth
    /// Primer día del mes, para mostrar su nombre.
    public let startDate: Date
    /// Celdas vacías antes del día 1, según el primer día de la semana de la región.
    public let leadingEmptyDays: Int
    /// Iniciales de los días de la semana, empezando por el primer día de la semana de la región.
    public let weekdaySymbols: [String]
    /// Uno por día del mes, del 1 al último.
    public let days: [Day]
    /// Día de hoy si el mes es el actual.
    public let today: Int?
    public let total: Money

    public init(
        period: YearMonth,
        startDate: Date,
        leadingEmptyDays: Int,
        weekdaySymbols: [String],
        days: [Day],
        today: Int?,
        total: Money
    ) {
        self.period = period
        self.startDate = startDate
        self.leadingEmptyDays = leadingEmptyDays
        self.weekdaySymbols = weekdaySymbols
        self.days = days
        self.today = today
        self.total = total
    }

    public var isCurrentMonth: Bool { today != nil }

    public struct Day: Identifiable, Equatable, Sendable {
        public let day: Int
        public let date: Date
        public let count: Int
        public let paidCount: Int
        public let total: Money

        public init(day: Int, date: Date, count: Int, paidCount: Int, total: Money) {
            self.day = day
            self.date = date
            self.count = count
            self.paidCount = paidCount
            self.total = total
        }

        public var id: Int { day }
        /// CAL-01
        public var hasPayments: Bool { count > 0 }
    }
}
