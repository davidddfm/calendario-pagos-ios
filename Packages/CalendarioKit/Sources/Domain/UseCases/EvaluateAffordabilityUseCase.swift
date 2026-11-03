/// ¿Puedo costearlo? (HER-01 a HER-03). Solo lee datos.
public struct EvaluateAffordabilityUseCase {
    private let payments: any PaymentRepository
    private let settings: any SettingsRepository
    private let clock: any DateProviding

    public init(payments: any PaymentRepository, settings: any SettingsRepository, clock: any DateProviding) {
        self.payments = payments
        self.settings = settings
        self.clock = clock
    }

    /// `nil` sin salario configurado (S-05).
    public func execute(newExpense: Money, kind: ExpenseKind) throws -> AffordabilityResult? {
        guard let salary = settings.load().monthlySalary else { return nil }
        return AffordabilityCalculator.evaluate(
            salary: salary, newExpense: newExpense, kind: kind,
            activePayments: try payments.activePayments(clock: clock))
    }
}
