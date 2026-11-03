/// Plan 50/30/20 (HER-07).
public struct GetBudgetPlanUseCase {
    private let settings: any SettingsRepository

    public init(settings: any SettingsRepository) {
        self.settings = settings
    }

    /// `nil` sin salario configurado (S-05).
    public func execute() -> BudgetPlan? {
        settings.load().monthlySalary.map(BudgetPlanCalculator.plan(salary:))
    }
}
