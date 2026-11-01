import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("NOT · Planificación de avisos", .tags(.reminders))
struct ReminderPlannerTests {
    let calendar = Calendar.testGregorian

    private func plan(
        now: Date,
        settings: ReminderSettings = ReminderSettings(),
        payments: [Payment],
        records: [PaymentRecord] = []
    ) -> [ReminderPlan] {
        ReminderPlanner.plan(
            now: now, settings: settings, payments: payments, currentMonthRecords: records, calendar: calendar)
    }

    @Test("NOT-05 · Desactivados no programan nada")
    func disabled() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 1, hour: 6)
        let payment = Payment.fixture(day: 1, createdAt: now)
        #expect(plan(now: now, settings: ReminderSettings(isEnabled: false), payments: [payment]).isEmpty)
    }

    @Test("NOT-01 / NOT-03 · Un aviso a las 8:00 solo en días con pagos, como máximo uno por día")
    func onePerDayWithPayments() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 1, hour: 6)
        let payments = [
            Payment.fixture(name: "Renta", day: 1, createdAt: now),
            Payment.fixture(name: "Agua", day: 1, createdAt: now),
            Payment.fixture(name: "Luz", day: 15, createdAt: now),
        ]
        let plans = plan(now: now, payments: payments)

        let first = try #require(plans.first)
        #expect(first.identifier == "reminder.2026-10-01")
        #expect(first.fireDate == DateComponents(year: 2026, month: 10, day: 1, hour: 8, minute: 0))
        #expect(first.pendingNames == ["Agua", "Renta"])
        #expect(Set(plans.map(\.identifier)).count == plans.count)
        // Del 1 de octubre al 29 de noviembre (60 días): 1 y 15 de cada mes.
        #expect(
            plans.map(\.identifier) == [
                "reminder.2026-10-01", "reminder.2026-10-15", "reminder.2026-11-01", "reminder.2026-11-15",
            ])
    }

    @Test("Si la hora de hoy ya pasó, el aviso de hoy no se programa")
    func skipsPastFireTime() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 1, hour: 8, minute: 0)
        let payment = Payment.fixture(day: 1, createdAt: now)
        #expect(plan(now: now, payments: [payment]).first?.identifier == "reminder.2026-11-01")
    }

    @Test("NOT-02 · Usa la hora configurada")
    func customTime() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 1, hour: 6)
        let payment = Payment.fixture(day: 2, createdAt: now)
        let first = try #require(
            plan(now: now, settings: ReminderSettings(hour: 21, minute: 30), payments: [payment]).first)
        #expect(first.fireDate.hour == 21)
        #expect(first.fireDate.minute == 30)
    }

    @Test("NOT-08 · Si todo lo de hoy ya se pagó, no se avisa; S-06 · solo se nombran los pendientes")
    func skipsPaid() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 1, hour: 6)
        let period = try YearMonth.make(2026, 10)
        let rent = Payment.fixture(name: "Renta", day: 1, createdAt: now)
        let water = Payment.fixture(name: "Agua", day: 2, createdAt: now)
        let power = Payment.fixture(name: "Luz", day: 2, createdAt: now)
        let records = [rent, water].map { PaymentRecord(snapshotOf: $0, period: period, markedAt: now) }

        let plans = plan(now: now, payments: [rent, water, power], records: records)

        #expect(plans.first?.identifier == "reminder.2026-10-02")
        #expect(plans.first?.pendingNames == ["Luz"])
        // El mes siguiente empieza pendiente (MAR-03).
        #expect(plans.contains { $0.identifier == "reminder.2026-11-01" && $0.pendingNames == ["Renta"] })
    }

    @Test("PAG-07 · El pago del 31 avisa el último día de los meses cortos")
    func effectiveDay() throws {
        let now = try calendar.date(year: 2027, month: 1, day: 31, hour: 9)
        let payment = Payment.fixture(day: 31, createdAt: now)
        #expect(
            plan(now: now, payments: [payment]).map(\.identifier) == [
                "reminder.2027-02-28", "reminder.2027-03-31",
            ])
    }

    @Test("La ventana no supera 60 días")
    func horizon() throws {
        let now = try calendar.date(year: 2026, month: 1, day: 1, hour: 0)
        let payments = (1...31).map { Payment.fixture(day: $0, createdAt: now) }
        let plans = plan(now: now, payments: payments)
        #expect(plans.count == ReminderPlanner.horizonDays)
        #expect(plans.last?.identifier == "reminder.2026-03-01")
    }

    @Test("Pagos eliminados y futuros no se avisan")
    func respectsActivity() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 1, hour: 6)
        let deleted = Payment.fixture(day: 5, createdAt: now, deletedAt: now)
        #expect(plan(now: now, payments: [deleted]).isEmpty)
    }

    @Test("NOT-07 · El plan solo lleva nombres, nunca montos")
    func noAmounts() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 1, hour: 6)
        let payment = Payment.fixture(name: "Renta", amount: Money(minorUnits: 123_456), day: 1, createdAt: now)
        let first = try #require(plan(now: now, payments: [payment]).first)
        #expect(first.pendingNames == ["Renta"])
        #expect(!first.pendingNames.joined().contains("1234"))
    }
}
