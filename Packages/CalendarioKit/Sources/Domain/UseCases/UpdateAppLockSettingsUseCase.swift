/// SEG-01 / SEG-02. Autenticar antes de activar es responsabilidad de la UI (§8.2).
public struct UpdateAppLockSettingsUseCase {
    private let settings: any SettingsRepository

    public init(settings: any SettingsRepository) {
        self.settings = settings
    }

    public func execute(_ appLock: AppLockSettings) throws {
        var current = settings.load()
        current.appLock = appLock
        try settings.save(current)
    }
}
