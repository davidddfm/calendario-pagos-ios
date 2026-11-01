/// Preferencias del usuario. Los valores por defecto viven aquí, no en el repositorio (§7.4).
public struct AppSettings: Equatable, Sendable {
    /// `nil` hasta completar MND-01.
    public var currency: Currency?
    /// `nil` = sin salario (DAS-04, QUI-04).
    public var monthlySalary: Money?
    public var reminders: ReminderSettings
    public var appLock: AppLockSettings
    public var hasCompletedOnboarding: Bool

    public init(
        currency: Currency? = nil,
        monthlySalary: Money? = nil,
        reminders: ReminderSettings = ReminderSettings(),
        appLock: AppLockSettings = AppLockSettings(),
        hasCompletedOnboarding: Bool = false
    ) {
        self.currency = currency
        self.monthlySalary = monthlySalary
        self.reminders = reminders
        self.appLock = appLock
        self.hasCompletedOnboarding = hasCompletedOnboarding
    }
}

// MARK: - Codable

/// Un campo nuevo o ilegible no invalida el resto (§7.4). La validación de rangos se hace al cargar.
extension AppSettings: Codable {
    private enum CodingKeys: String, CodingKey {
        case currency, monthlySalary, reminders, appLock, hasCompletedOnboarding
    }

    public init(from decoder: any Decoder) throws {
        let defaults = AppSettings()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.currency = container.decodeOrDefault(Currency?.self, forKey: .currency, default: defaults.currency)
        self.monthlySalary = container.decodeOrDefault(
            Money?.self, forKey: .monthlySalary, default: defaults.monthlySalary)
        self.reminders = container.decodeOrDefault(
            ReminderSettings.self, forKey: .reminders, default: defaults.reminders)
        self.appLock = container.decodeOrDefault(AppLockSettings.self, forKey: .appLock, default: defaults.appLock)
        self.hasCompletedOnboarding = container.decodeOrDefault(
            Bool.self, forKey: .hasCompletedOnboarding, default: defaults.hasCompletedOnboarding)
    }
}

extension KeyedDecodingContainer {
    /// Decodifica un campo opcional del JSON de ajustes. Un valor ausente o con tipo inválido no es un error:
    /// se usa el valor por defecto.
    func decodeOrDefault<T: Decodable>(_ type: T.Type, forKey key: Key, default defaultValue: T) -> T {
        guard contains(key), let value = try? decode(T.self, forKey: key) else { return defaultValue }
        return value
    }
}
