import Domain
import Foundation

extension Money {
    /// Monto en unidades enteras de la moneda (p. ej. `Money(major: 120)` = 120.00).
    public init(major: Int64) { self.init(minorUnits: major * 100) }
}

extension YearMonth {
    public static func make(_ year: Int, _ month: Int) throws -> YearMonth {
        guard let period = YearMonth(year: year, month: month) else { throw TestDateError() }
        return period
    }
}

extension Payment {
    public static func fixture(
        id: UUID = UUID(),
        name: String = "Internet",
        amount: Money = Money(major: 100),
        day: Int = 10,
        category: PaymentCategory = .utilities,
        createdAt: Date,
        deletedAt: Date? = nil
    ) -> Payment {
        Payment(
            id: id,
            name: name,
            amount: amount,
            dayOfMonth: day,
            category: category,
            createdAt: createdAt,
            updatedAt: createdAt,
            deletedAt: deletedAt
        )
    }
}
