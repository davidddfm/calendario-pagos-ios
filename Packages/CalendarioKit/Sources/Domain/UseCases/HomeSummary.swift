import Foundation

/// Contenido de Inicio (PAG-06 a PAG-08).
public struct HomeSummary: Sendable {
    public let today: Date
    /// "Para hoy": pagos cuyo día efectivo es hoy (PAG-06, PAG-07).
    public let todayItems: [MonthStatement.Item]
    /// "Análisis quincenal": siempre las dos quincenas, en orden (PAG-06).
    public let fortnights: [FortnightTotal]
    /// Lista completa del mes actual, para la búsqueda (PAG-05).
    public let allItems: [MonthStatement.Item]

    public init(
        today: Date,
        todayItems: [MonthStatement.Item],
        fortnights: [FortnightTotal],
        allItems: [MonthStatement.Item]
    ) {
        self.today = today
        self.todayItems = todayItems
        self.fortnights = fortnights
        self.allItems = allItems
    }

    /// PAG-08: sin pagos se muestra la bienvenida.
    public var isEmpty: Bool { allItems.isEmpty }

    public struct FortnightTotal: Identifiable, Equatable, Sendable {
        public let fortnight: Fortnight
        public let total: Money
        public let count: Int

        public init(fortnight: Fortnight, total: Money, count: Int) {
            self.fortnight = fortnight
            self.total = total
            self.count = count
        }

        public var id: Fortnight { fortnight }
    }
}
