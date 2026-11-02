import Domain
import Foundation
import Testing

@testable import Persistence

@Suite("§7.4 · Ajustes en UserDefaults del App Group", .tags(.settings))
struct SettingsRepositoryTests {
    let suiteName = "test.settings.\(UUID().uuidString)"
    let defaults: UserDefaults

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
    }

    private func repository(hasPayments: Bool = false) -> UserDefaultsSettingsRepository {
        UserDefaultsSettingsRepository(defaults: defaults, hasStoredPayments: { hasPayments })
    }

    @Test("Sin datos guardados, valores por defecto y onboarding pendiente")
    func emptyStore() {
        let settings = repository().load()
        #expect(settings == AppSettings())
        #expect(settings.needsOnboarding)
    }

    @Test func roundTrip() throws {
        let settings = AppSettings(
            currency: .eur, monthlySalary: Money(major: 2_500), reminders: ReminderSettings(hour: 21, minute: 5),
            hasCompletedOnboarding: true)
        try repository().save(settings)
        #expect(repository().load() == settings)
        #expect(!repository().load().needsOnboarding)
    }

    @Test("JSON ilegible: valores por defecto, sin repetir el onboarding si hay pagos")
    func unreadableJSON() {
        defaults.set(Data("no es json".utf8), forKey: UserDefaultsSettingsRepository.key)
        #expect(repository(hasPayments: true).load().hasCompletedOnboarding)
        #expect(!repository(hasPayments: false).load().hasCompletedOnboarding)
    }

    @Test("Valores fuera de rango vuelven al valor por defecto")
    func outOfRange() throws {
        let json =
            #"{"currency":"USD","monthlySalary":999999901,"hasCompletedOnboarding":true,"reminders":{"isEnabled":true,"hour":25,"minute":0}}"#
        defaults.set(Data(json.utf8), forKey: UserDefaultsSettingsRepository.key)
        let settings = repository().load()
        #expect(settings.monthlySalary == nil)
        #expect(settings.reminders.hour == 8)
        #expect(settings.reminders.isEnabled)
        #expect(settings.currency == .usd)
    }

    @Test("MND-01 · Bandera de onboarding sin moneda vuelve a pedir la moneda")
    func onboardingWithoutCurrency() {
        defaults.set(Data(#"{"hasCompletedOnboarding":true}"#.utf8), forKey: UserDefaultsSettingsRepository.key)
        #expect(repository().load().needsOnboarding)
    }
}
