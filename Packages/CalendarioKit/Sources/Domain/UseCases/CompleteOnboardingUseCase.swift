/// MND-01: la moneda se elige antes de registrar nada.
public struct CompleteOnboardingUseCase {
    private let settings: any SettingsRepository
    private let observer: any DataChangeObserving

    public init(settings: any SettingsRepository, observer: any DataChangeObserving) {
        self.settings = settings
        self.observer = observer
    }

    public func execute(currency: Currency) throws {
        var current = settings.load()
        current.currency = currency
        current.hasCompletedOnboarding = true
        try settings.save(current)
        observer.dataDidChange(.currency)
    }
}
