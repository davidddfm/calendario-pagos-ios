import Domain
import Foundation
import os

/// Guarda `AppSettings` como un único JSON versionado en el App Group (§7.4).
public final class UserDefaultsSettingsRepository: SettingsRepository {
    static let key = "settings.v1"

    private let defaults: UserDefaults
    private let hasStoredPayments: () -> Bool

    /// - Parameter hasStoredPayments: si el JSON es ilegible y ya hay pagos, no se repite el onboarding.
    public init(defaults: UserDefaults, hasStoredPayments: @escaping () -> Bool) {
        self.defaults = defaults
        self.hasStoredPayments = hasStoredPayments
    }

    public func load() -> AppSettings {
        guard let data = defaults.data(forKey: Self.key) else { return AppSettings() }
        do {
            return Self.sanitized(try JSONDecoder().decode(AppSettings.self, from: data))
        } catch {
            Logger.persistence.error("Ajustes ilegibles: \(String(describing: type(of: error)), privacy: .public)")
            return AppSettings(hasCompletedOnboarding: hasStoredPayments())
        }
    }

    public func save(_ settings: AppSettings) throws {
        do {
            defaults.set(try JSONEncoder().encode(settings), forKey: Self.key)
        } catch {
            Logger.persistence.error("No se pudieron codificar los ajustes")
            throw PersistenceError.saveFailed
        }
    }

    /// Los valores fuera de rango vuelven a su valor por defecto (§7.4).
    static func sanitized(_ settings: AppSettings) -> AppSettings {
        var settings = settings
        if let salary = settings.monthlySalary, !SalaryValidator.isValid(salary) {
            settings.monthlySalary = nil
        }
        if !(0...23).contains(settings.reminders.hour) || !(0...59).contains(settings.reminders.minute) {
            let defaults = ReminderSettings()
            settings.reminders.hour = defaults.hour
            settings.reminders.minute = defaults.minute
        }
        return settings
    }
}
