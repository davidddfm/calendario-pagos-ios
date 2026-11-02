import Foundation

/// Estado de un mes: qué pagos existían, cuáles se pagaron y con qué datos (MAR, HIS, CAL, QUI).
public struct MonthStatement: Sendable {
    public let period: YearMonth
    /// Ordenados por día efectivo y nombre.
    public let items: [Item]

    public init(period: YearMonth, items: [Item]) {
        self.period = period
        self.items = items
    }

    public var paid: [Item] { items.filter(\.isPaid) }
    public var pending: [Item] { items.filter { !$0.isPaid } }
    public var paidTotal: Money { paid.map(\.displayAmount).sum() }
    public var total: Money { items.map(\.displayAmount).sum() }

    /// HIS-01: proporción de pagos cumplidos (0...1).
    public var compliance: Double { items.isEmpty ? 0 : Double(paid.count) / Double(items.count) }

    public func items(in fortnight: Fortnight) -> [Item] { items.filter { $0.fortnight == fortnight } }

    public func items(onEffectiveDay day: Int) -> [Item] { items.filter { $0.effectiveDay == day } }

    public struct Item: Identifiable, Hashable, Sendable {
        /// `paymentID`
        public let id: UUID
        public let name: String
        public let category: PaymentCategory
        /// Día programado del pago; decide la quincena (PAG-03).
        public let scheduledDay: Int
        /// Día en que cae el pago en este mes (PAG-07).
        public let effectiveDay: Int
        /// `nil` si el pago ya no existe en el mes (se eliminó después de pagarlo).
        public let currentAmount: Money?
        /// `nil` = pendiente.
        public let record: PaymentRecord?

        public init(
            id: UUID,
            name: String,
            category: PaymentCategory,
            scheduledDay: Int,
            effectiveDay: Int,
            currentAmount: Money?,
            record: PaymentRecord?
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.scheduledDay = scheduledDay
            self.effectiveDay = effectiveDay
            self.currentAmount = currentAmount
            self.record = record
        }

        public var isPaid: Bool { record != nil }

        /// `false` para un pago eliminado cuyo registro sigue en el mes: solo existe en el Historial.
        public var paymentExists: Bool { currentAmount != nil }
        public var fortnight: Fortnight { Fortnight(dayOfMonth: scheduledDay) }

        /// Pagado: monto registrado. Pendiente: monto actual.
        public var displayAmount: Money { record?.amount ?? currentAmount ?? .zero }

        /// MAR-05: "pagado por $X" cuando el monto cambió tras marcarlo.
        public var paidAmountDiffers: Bool {
            guard let record, let currentAmount else { return false }
            return record.amount != currentAmount
        }
    }
}
