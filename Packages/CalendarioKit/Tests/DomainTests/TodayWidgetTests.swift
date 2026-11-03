import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("WID-01 / WID-04 · Pagos de hoy del widget", .tags(.widget))
struct GetTodayWidgetSnapshotUseCaseTests {
    let calendar = Calendar.testGregorian
    let payments = InMemoryPaymentRepository()
    let records = InMemoryPaymentRecordRepository()
    let createdAt: Date

    init() throws {
        createdAt = try calendar.date(year: 2026, month: 1, day: 1)
    }

    private var useCase: GetTodayWidgetSnapshotUseCase {
        GetTodayWidgetSnapshotUseCase(payments: payments, records: records, calendar: calendar)
    }

    @Test("Solo los pagos de hoy, ordenados por nombre y con su estado")
    func todayItems() throws {
        let rent = Payment.fixture(name: "Renta", day: 15, createdAt: createdAt)
        let gym = Payment.fixture(name: "Gimnasio", day: 15, createdAt: createdAt)
        try payments.insert(rent)
        try payments.insert(gym)
        try payments.insert(.fixture(name: "Luz", day: 16, createdAt: createdAt))
        try records.insert(PaymentRecord(snapshotOf: rent, period: .make(2026, 10), markedAt: createdAt))

        let snapshot = try useCase.execute(for: calendar.date(year: 2026, month: 10, day: 15))
        #expect(snapshot.items.map(\.name) == ["Gimnasio", "Renta"])
        #expect(snapshot.items.map(\.isPaid) == [false, true])
        #expect(snapshot.paidCount == 1)
        #expect(snapshot.pendingCount == 1)
        #expect(snapshot.totalCount == 2)
    }

    @Test("PAG-07 · Un pago del día 31 aparece el último día de febrero")
    func effectiveDay() throws {
        try payments.insert(.fixture(name: "Tarjeta", day: 31, createdAt: createdAt))
        let snapshot = try useCase.execute(for: calendar.date(year: 2026, month: 2, day: 28))
        #expect(snapshot.items.map(\.name) == ["Tarjeta"])
    }

    @Test("Un pago eliminado después de pagarlo ya no aparece")
    func deletedPayment() throws {
        let today = try calendar.date(year: 2026, month: 10, day: 15)
        let rent = Payment.fixture(name: "Renta", day: 15, createdAt: createdAt, deletedAt: today)
        try payments.insert(rent)
        try records.insert(PaymentRecord(snapshotOf: rent, period: .make(2026, 10), markedAt: createdAt))
        #expect(try useCase.execute(for: today).items.isEmpty)
    }

    @Test("MAR-03 · La entrada de un mes nuevo empieza con todo pendiente")
    func newMonth() throws {
        let rent = Payment.fixture(name: "Renta", day: 1, createdAt: createdAt)
        try payments.insert(rent)
        try records.insert(PaymentRecord(snapshotOf: rent, period: .make(2026, 10), markedAt: createdAt))
        let snapshot = try useCase.execute(for: calendar.date(year: 2026, month: 11, day: 1, hour: 0))
        #expect(snapshot.items.map(\.isPaid) == [false])
    }

    @Test("WID-01 · El tipo del widget no tiene ningún campo de dinero")
    func noMoney() {
        let item = TodaySnapshot.Item(id: UUID(), name: "Renta", isPaid: false)
        let snapshot = TodaySnapshot(date: createdAt, items: [item])
        for mirror in [Mirror(reflecting: snapshot), Mirror(reflecting: item)] {
            for child in mirror.children {
                #expect(!(child.value is Money))
                #expect(!(child.value is Decimal))
                #expect(!(child.value is Int64))
            }
        }
    }
}

@Suite("WID-04 · Línea de tiempo del widget", .tags(.widget))
struct WidgetTimelinePlannerTests {
    @Test("Una entrada ahora y otra a medianoche; se recarga a medianoche")
    func midnight() throws {
        let calendar = Calendar.testGregorian
        let now = try calendar.date(year: 2026, month: 10, day: 31, hour: 22, minute: 30)
        let plan = WidgetTimelinePlanner.plan(now: now, calendar: calendar)
        let midnight = try calendar.date(year: 2026, month: 11, day: 1, hour: 0)
        #expect(plan.entryDates == [now, midnight])
        #expect(plan.reloadDate == midnight)
    }

    @Test("Con cambio de horario la medianoche no es ahora + 24 h")
    func daylightSaving() throws {
        var calendar = Calendar.testGregorian
        calendar.timeZone = try #require(TimeZone(identifier: "America/New_York"))
        // El 8 de marzo de 2026 dura 23 horas en Nueva York.
        let now = try calendar.date(year: 2026, month: 3, day: 8, hour: 0, minute: 30)
        let plan = WidgetTimelinePlanner.plan(now: now, calendar: calendar)
        #expect(plan.reloadDate == (try calendar.date(year: 2026, month: 3, day: 9, hour: 0)))
        #expect(plan.reloadDate.timeIntervalSince(now) == 22.5 * 60 * 60)
    }

    @Test("Reintento a los 15 minutos")
    func retry() {
        let now = Date(timeIntervalSince1970: 0)
        let plan = WidgetTimelinePlanner.retry(now: now)
        #expect(plan.entryDates == [now])
        #expect(plan.reloadDate == now.addingTimeInterval(15 * 60))
    }
}
