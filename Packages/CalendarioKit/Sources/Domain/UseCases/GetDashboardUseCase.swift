/// DAS-01 a DAS-04.
public struct GetDashboardUseCase {
    private let payments: any PaymentRepository
    private let settings: any SettingsRepository
    private let clock: any DateProviding

    public init(payments: any PaymentRepository, settings: any SettingsRepository, clock: any DateProviding) {
        self.payments = payments
        self.settings = settings
        self.clock = clock
    }

    public func execute() throws -> DashboardSummary {
        DashboardCalculator.summary(
            salary: settings.load().monthlySalary, activePayments: try payments.activePayments(clock: clock))
    }
}
