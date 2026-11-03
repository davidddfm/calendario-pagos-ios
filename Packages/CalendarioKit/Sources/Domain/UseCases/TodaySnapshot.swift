import Foundation

/// WID-01: contenido del widget "Pagos de hoy". No tiene montos, totales ni salario.
public struct TodaySnapshot: Equatable, Sendable {
    public let date: Date
    /// Pagos vigentes cuyo día efectivo es `date`, ordenados por nombre (PAG-07).
    public let items: [Item]

    public init(date: Date, items: [Item]) {
        self.date = date
        self.items = items
    }

    public var paidCount: Int { items.count(where: \.isPaid) }
    public var pendingCount: Int { items.count - paidCount }
    public var totalCount: Int { items.count }

    public struct Item: Identifiable, Equatable, Sendable {
        /// `paymentID`
        public let id: UUID
        public let name: String
        public let isPaid: Bool

        public init(id: UUID, name: String, isPaid: Bool) {
            self.id = id
            self.name = name
            self.isPaid = isPaid
        }
    }
}
