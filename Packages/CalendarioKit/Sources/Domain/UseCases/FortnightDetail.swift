/// Pantalla de una quincena del mes actual (QUI-01 a QUI-04).
public struct FortnightDetail: Sendable {
    public let fortnight: Fortnight
    public let period: YearMonth
    public let items: [MonthStatement.Item]
    public let total: Money
    /// QUI-02 / S-09: salario × 50 % menos el total de la quincena. `nil` sin salario (QUI-04).
    public let remaining: Money?

    public init(
        fortnight: Fortnight, period: YearMonth, items: [MonthStatement.Item], total: Money, remaining: Money?
    ) {
        self.fortnight = fortnight
        self.period = period
        self.items = items
        self.total = total
        self.remaining = remaining
    }
}
