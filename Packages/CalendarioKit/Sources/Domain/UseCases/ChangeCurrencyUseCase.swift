/// MND-03: solo cambia el símbolo; los montos no se convierten. La advertencia previa es de UI.
public struct ChangeCurrencyUseCase {
    private let settings: any SettingsRepository
    private let observer: any DataChangeObserving

    public init(settings: any SettingsRepository, observer: any DataChangeObserving) {
        self.settings = settings
        self.observer = observer
    }

    public func execute(_ currency: Currency) throws {
        var current = settings.load()
        guard current.currency != currency else { return }
        current.currency = currency
        try settings.save(current)
        observer.dataDidChange(.currency)
    }
}
