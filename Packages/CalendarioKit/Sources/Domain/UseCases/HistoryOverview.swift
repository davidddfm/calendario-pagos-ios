import Foundation

/// Historial mensual (HIS-01, HIS-02).
public struct HistoryOverview: Sendable {
    /// S-04: del mes del pago más antiguo al actual, en orden descendente.
    public let months: [MonthSummary]
    /// HIS-02: los últimos 6 meses incluido el actual, del más antiguo al más reciente.
    public let chart: [MonthSummary]

    public init(months: [MonthSummary], chart: [MonthSummary]) {
        self.months = months
        self.chart = chart
    }

    public var isEmpty: Bool { months.isEmpty }

    public struct MonthSummary: Identifiable, Equatable, Sendable {
        public let period: YearMonth
        /// Primer día del mes, para mostrar su nombre.
        public let startDate: Date
        public let paidTotal: Money
        public let paidCount: Int
        public let totalCount: Int

        public init(period: YearMonth, startDate: Date, paidTotal: Money, paidCount: Int, totalCount: Int) {
            self.period = period
            self.startDate = startDate
            self.paidTotal = paidTotal
            self.paidCount = paidCount
            self.totalCount = totalCount
        }

        public var id: Int { period.key }

        /// HIS-01: 0...1
        public var compliance: Double { totalCount == 0 ? 0 : Double(paidCount) / Double(totalCount) }
    }
}
