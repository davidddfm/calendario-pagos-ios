import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("NOT-07 · Texto del aviso", .tags(.reminders))
struct ReminderTextTests {
    let locale = Locale(identifier: "es_MX")

    @Test("Cuenta los pagos y lista los nombres, sin montos")
    func body() {
        #expect(ReminderText.body(names: ["Renta"], locale: locale) == "Tienes 1 pago hoy: Renta.")
        #expect(ReminderText.body(names: ["Luz", "Renta"], locale: locale) == "Tienes 2 pagos hoy: Luz y Renta.")
        #expect(
            ReminderText.body(names: ["A", "B", "C", "D", "E", "F"], locale: locale)
                == "Tienes 6 pagos hoy: A, B, C, D y 2 más.")
        #expect(ReminderText.title(locale: locale) == "Pagos de hoy")
    }
}

@Suite("NOT-01 a NOT-08 · Reprogramación de avisos", .tags(.reminders))
struct ReminderUseCaseTests {
    let calendar = Calendar.testGregorian
    let clock: FixedClock
    let payments: InMemoryPaymentRepository
    let records = InMemoryPaymentRecordRepository()
    let settings = InMemorySettingsRepository(AppSettings(currency: .usd, hasCompletedOnboarding: true))
    let observer = SpyChangeObserver()

    init() throws {
        clock = FixedClock(now: try calendar.date(year: 2026, month: 10, day: 10, hour: 7))
        payments = InMemoryPaymentRepository([
            Payment.fixture(name: "Renta", day: 10, createdAt: try calendar.date(year: 2026, month: 1, day: 1))
        ])
    }

    private func reschedule(_ scheduler: SpyReminderScheduler) -> RescheduleRemindersUseCase {
        RescheduleRemindersUseCase(
            payments: payments, records: records, settings: settings, scheduler: scheduler, clock: clock)
    }

    @Test("Con permiso, programa la ventana desde hoy")
    func authorized() async throws {
        let scheduler = SpyReminderScheduler(status: .authorized)
        try await reschedule(scheduler).execute()
        let plans = try #require(await scheduler.scheduled)
        #expect(plans.first?.identifier == "reminder.2026-10-10")
        #expect(plans.first?.pendingNames == ["Renta"])
        #expect(plans.count == 2)  // 10 de octubre y 10 de noviembre dentro de 60 días
    }

    @Test("NOT-05 / NOT-06 · Apagados o sin permiso: se quitan todos", arguments: [true, false])
    func removesAll(disabledBySetting: Bool) async throws {
        let scheduler = SpyReminderScheduler(status: disabledBySetting ? .authorized : .denied)
        if disabledBySetting {
            try UpdateReminderSettingsUseCase(settings: settings, observer: observer)
                .execute(isEnabled: false, hour: 8, minute: 0)
        }
        try await reschedule(scheduler).execute()
        #expect(await scheduler.removeAllCount == 1)
        #expect(await scheduler.scheduled == [])
    }

    @Test("NOT-02 · Hora inválida", arguments: [(24, 0), (-1, 0), (8, 60)])
    func invalidTime(hour: Int, minute: Int) {
        #expect(throws: DomainError.invalidReminderTime) {
            try UpdateReminderSettingsUseCase(settings: settings, observer: observer)
                .execute(isEnabled: true, hour: hour, minute: minute)
        }
        #expect(observer.changes.isEmpty)
    }

    @Test("S-08 · El permiso se ofrece solo si no se decidió y nunca dos veces")
    func offerPermission() async throws {
        let scheduler = SpyReminderScheduler(status: .notDetermined)
        let shouldOffer = ShouldOfferReminderPermissionUseCase(settings: settings, scheduler: scheduler)
        #expect(await shouldOffer.execute())

        let status = try await RequestReminderPermissionUseCase(
            settings: settings, scheduler: scheduler, observer: observer
        ).execute(accepted: true)
        #expect(status == .authorized)
        #expect(observer.changes == [.reminderSettings])
        #expect(await !shouldOffer.execute())
        #expect(await GetReminderAuthorizationUseCase(scheduler: scheduler).execute() == .authorized)
    }

    @Test("S-08 · Ya autorizado o con avisos apagados no se ofrece")
    func noOffer() async throws {
        #expect(
            await !ShouldOfferReminderPermissionUseCase(
                settings: settings, scheduler: SpyReminderScheduler(status: .authorized)
            ).execute())
        try UpdateReminderSettingsUseCase(settings: settings, observer: observer).execute(
            isEnabled: false, hour: 8, minute: 0)
        #expect(
            await !ShouldOfferReminderPermissionUseCase(
                settings: settings, scheduler: SpyReminderScheduler(status: .notDetermined)
            ).execute())
    }

    @Test("SEG-01 / SEG-02 · Guardar los ajustes de bloqueo")
    func appLock() throws {
        try UpdateAppLockSettingsUseCase(settings: settings)
            .execute(AppLockSettings(isEnabled: true, gracePeriod: .immediately))
        #expect(settings.stored.appLock == AppLockSettings(isEnabled: true, gracePeriod: .immediately))
    }
}
