import Foundation

/// Detalle de un día del Calendario (CAL-03 a CAL-05).
public struct DayDetail: Sendable {
    public let date: Date
    public let period: YearMonth
    public let items: [MonthStatement.Item]
    /// MAR-02 / CAL-04: solo el mes actual tiene casillas.
    public let isEditable: Bool

    public init(date: Date, period: YearMonth, items: [MonthStatement.Item], isEditable: Bool) {
        self.date = date
        self.period = period
        self.items = items
        self.isEditable = isEditable
    }

    public var total: Money { items.map(\.displayAmount).sum() }
    public var paidCount: Int { items.count(where: \.isPaid) }

    /// CAL-04: proporción de pagos pagados (0...1).
    public var progress: Double { items.isEmpty ? 0 : Double(paidCount) / Double(items.count) }
}
