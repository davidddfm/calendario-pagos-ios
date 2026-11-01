import Foundation
import Testing

@testable import Domain

@Suite("§7.4 · Ajustes robustos ante JSON dañado", .tags(.settings))
struct AppSettingsTests {
    private func decode(_ json: String) throws -> AppSettings {
        try JSONDecoder().decode(AppSettings.self, from: Data(json.utf8))
    }

    @Test("NOT-01 / SEG-01 / SEG-02 · Valores por defecto")
    func defaults() throws {
        let settings = try decode("{}")
        #expect(settings == AppSettings())
        #expect(settings.currency == nil)
        #expect(settings.monthlySalary == nil)
        #expect(settings.reminders == ReminderSettings(isEnabled: true, hour: 8, minute: 0))
        #expect(settings.appLock == AppLockSettings(isEnabled: false, gracePeriod: .oneMinute))
        #expect(!settings.hasCompletedOnboarding)
    }

    @Test("Un campo ilegible no invalida el resto")
    func unreadableFieldFallsBack() throws {
        let settings = try decode(
            """
            {"currency":"GBP","monthlySalary":"mucho","hasCompletedOnboarding":true,
             "reminders":{"isEnabled":false,"hour":"ocho"},"appLock":{"isEnabled":true,"gracePeriod":42}}
            """)
        #expect(settings.currency == nil)
        #expect(settings.monthlySalary == nil)
        #expect(settings.hasCompletedOnboarding)
        #expect(settings.reminders == ReminderSettings(isEnabled: false, hour: 8, minute: 0))
        #expect(settings.appLock == AppLockSettings(isEnabled: true, gracePeriod: .oneMinute))
    }

    @Test func roundTrip() throws {
        let original = AppSettings(
            currency: .eur,
            monthlySalary: Money(minorUnits: 250_000),
            reminders: ReminderSettings(isEnabled: true, hour: 20, minute: 15),
            appLock: AppLockSettings(isEnabled: true, gracePeriod: .fiveMinutes),
            hasCompletedOnboarding: true)
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(AppSettings.self, from: data) == original)
    }

    @Test("JSON que no es un objeto lanza error para que el repositorio cargue valores por defecto")
    func notAnObject() {
        #expect(throws: (any Error).self) { try decode("[1,2,3]") }
    }
}
