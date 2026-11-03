/// Valores actuales para la pantalla de Ajustes.
public struct GetSettingsUseCase {
    private let settings: any SettingsRepository

    public init(settings: any SettingsRepository) {
        self.settings = settings
    }

    public func execute() -> AppSettings { settings.load() }
}
