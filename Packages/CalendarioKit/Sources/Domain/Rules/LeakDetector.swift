import Foundation

/// HER-04 a HER-06.
public struct LeakReport: Equatable, Sendable {
    /// De mayor a menor monto.
    public let items: [Item]
    /// HER-05
    public let annualTotal: Money

    public init(items: [Item], annualTotal: Money) {
        self.items = items
        self.annualTotal = annualTotal
    }

    public struct Item: Identifiable, Equatable, Sendable {
        public let id: UUID
        public let name: String
        public let category: PaymentCategory
        public let monthlyAmount: Money
        public let annualCost: Money

        public init(id: UUID, name: String, category: PaymentCategory, monthlyAmount: Money, annualCost: Money) {
            self.id = id
            self.name = name
            self.category = category
            self.monthlyAmount = monthlyAmount
            self.annualCost = annualCost
        }
    }
}

/// Detector de fugas: costo anual de cada pago, tratado como gasto mensual recurrente (HER-06).
public enum LeakDetector {
    /// - Parameter activePayments: pagos activos en el mes actual.
    public static func report(activePayments: [Payment]) -> LeakReport {
        let items =
            activePayments
            .sorted { lhs, rhs in
                if lhs.amount != rhs.amount { return lhs.amount > rhs.amount }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
            .map {
                LeakReport.Item(
                    id: $0.id,
                    name: $0.name,
                    category: $0.category,
                    monthlyAmount: $0.amount,
                    annualCost: $0.amount.multiplied(by: 12)
                )
            }
        return LeakReport(items: items, annualTotal: items.map(\.annualCost).sum())
    }
}
