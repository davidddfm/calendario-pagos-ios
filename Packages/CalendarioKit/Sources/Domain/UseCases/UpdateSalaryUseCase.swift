/// CFG-01, DAS-05. `nil` quita el salario.
public struct UpdateSalaryUseCase {
    private let settings: any SettingsRepository
    private let observer: any DataChangeObserving

    public init(settings: any SettingsRepository, observer: any DataChangeObserving) {
        self.settings = settings
        self.observer = observer
    }

    public func execute(_ salary: Money?) throws {
        var current = settings.load()
        current.monthlySalary = try SalaryValidator.validated(salary)
        try settings.save(current)
        observer.dataDidChange(.salary)
    }
}
