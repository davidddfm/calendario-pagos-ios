import Foundation

/// MAR-04: instantánea inmutable del pago en el momento de marcarlo.
public struct PaymentRecord: Identifiable, Hashable, Sendable {
    public let id: UUID
    public let paymentID: UUID
    public let period: YearMonth
    public let name: String
    public let amount: Money
    public let category: PaymentCategory
    public let markedAt: Date

    public init(snapshotOf payment: Payment, period: YearMonth, markedAt: Date) {
        self.init(
            id: UUID(),
            paymentID: payment.id,
            period: period,
            name: payment.name,
            amount: payment.amount,
            category: payment.category,
            markedAt: markedAt
        )
    }

    /// Reconstrucción desde el almacén (§7.5).
    public init(
        id: UUID,
        paymentID: UUID,
        period: YearMonth,
        name: String,
        amount: Money,
        category: PaymentCategory,
        markedAt: Date
    ) {
        self.id = id
        self.paymentID = paymentID
        self.period = period
        self.name = name
        self.amount = amount
        self.category = category
        self.markedAt = markedAt
    }
}
