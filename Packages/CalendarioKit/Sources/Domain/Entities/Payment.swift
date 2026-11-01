import Foundation

/// Compromiso mensual que se repite cada mes en el mismo día.
public struct Payment: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var name: String
    public var amount: Money
    /// 1...31 (PAG-01)
    public var dayOfMonth: Int
    /// PAG-02
    public var category: PaymentCategory
    public let createdAt: Date
    public var updatedAt: Date
    /// ADR-07: borrado lógico, para que el Historial conserve los pagos de meses pasados.
    public var deletedAt: Date?

    public init(
        id: UUID,
        name: String,
        amount: Money,
        dayOfMonth: Int,
        category: PaymentCategory,
        createdAt: Date,
        updatedAt: Date,
        deletedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.dayOfMonth = dayOfMonth
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }

    /// PAG-03
    public var fortnight: Fortnight { Fortnight(dayOfMonth: dayOfMonth) }

    /// Un pago existe en un mes si se creó ese mes o antes (S-07) y no se eliminó ese mes ni antes.
    public func isActive(in period: YearMonth, calendar: Calendar) -> Bool {
        guard YearMonth(containing: createdAt, calendar: calendar) <= period else { return false }
        guard let deletedAt else { return true }
        return YearMonth(containing: deletedAt, calendar: calendar) > period
    }
}

extension Sequence where Element == Payment {
    /// Pagos que existen en `period` (ver `Payment.isActive(in:calendar:)`).
    public func active(in period: YearMonth, calendar: Calendar) -> [Payment] {
        filter { $0.isActive(in: period, calendar: calendar) }
    }
}
