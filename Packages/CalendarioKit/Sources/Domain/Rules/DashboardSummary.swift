/// Datos de las tarjetas del Dashboard (DAS).
public struct DashboardSummary: Equatable, Sendable {
    /// Suma de los pagos activos del mes actual.
    public let totalMonthly: Money
    /// `nil` sin salario configurado (DAS-04).
    public let availability: Availability?
    /// DAS-03: solo categorías con pagos, de mayor a menor.
    public let categoryShares: [CategoryShare]
    public let emergencyFund: EmergencyFund

    public init(
        totalMonthly: Money,
        availability: Availability?,
        categoryShares: [CategoryShare],
        emergencyFund: EmergencyFund
    ) {
        self.totalMonthly = totalMonthly
        self.availability = availability
        self.categoryShares = categoryShares
        self.emergencyFund = emergencyFund
    }

    public struct Availability: Equatable, Sendable {
        public let salary: Money
        /// Puede ser negativo (DAS-02).
        public let available: Money
        public let spentRatio: Double
        public let level: SpendingLevel

        public init(salary: Money, available: Money, spentRatio: Double, level: SpendingLevel) {
            self.salary = salary
            self.available = available
            self.spentRatio = spentRatio
            self.level = level
        }

        /// DAS-02
        public var isOverdrawn: Bool { available.isNegative }
    }

    /// DAS-01: verde hasta el 50 % del salario, naranja por encima.
    public enum SpendingLevel: Sendable {
        case healthy, warning
    }

    public struct CategoryShare: Equatable, Sendable {
        public let category: PaymentCategory
        public let total: Money
        /// 0...1
        public let share: Double

        public init(category: PaymentCategory, total: Money, share: Double) {
            self.category = category
            self.total = total
            self.share = share
        }
    }

    public struct EmergencyFund: Equatable, Sendable {
        public let threeMonths: Money
        public let sixMonths: Money
        public let twelveMonths: Money

        public init(threeMonths: Money, sixMonths: Money, twelveMonths: Money) {
            self.threeMonths = threeMonths
            self.sixMonths = sixMonths
            self.twelveMonths = twelveMonths
        }
    }
}
