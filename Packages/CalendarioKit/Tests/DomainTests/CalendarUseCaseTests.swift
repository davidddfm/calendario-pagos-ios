import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("CAL-01 a CAL-05 · Calendario y detalle del día", .tags(.history))
struct CalendarUseCaseTests {
    let calendar = Calendar.testGregorian
    let clock: FixedClock
    let payments: InMemoryPaymentRepository
    let records = InMemoryPaymentRecordRepository()
    let rent: Payment
    let phone: Payment
    let gym: Payment

    init() throws {
        clock = FixedClock(now: try calendar.date(year: 2026, month: 10, day: 15))
        let created = try calendar.date(year: 2026, month: 1, day: 1)
        rent = Payment.fixture(name: "Renta", amount: Money(major: 500), day: 1, createdAt: created)
        phone = Payment.fixture(name: "Teléfono", amount: Money(major: 30), day: 31, createdAt: created)
        // Pagado en septiembre y eliminado en octubre.
        gym = Payment.fixture(
            name: "Gimnasio", amount: Money(major: 40), day: 1, createdAt: created,
            deletedAt: try calendar.date(year: 2026, month: 10, day: 5))
        payments = InMemoryPaymentRepository([rent, phone, gym])
        try records.insert(
            PaymentRecord(
                snapshotOf: gym, period: .make(2026, 9), markedAt: try calendar.date(year: 2026, month: 9, day: 1)))
        try records.insert(
            PaymentRecord(
                snapshotOf: rent, period: .make(2026, 10), markedAt: try calendar.date(year: 2026, month: 10, day: 1)))
    }

    private func month(_ year: Int, _ month: Int, calendar: Calendar? = nil) throws -> CalendarMonth {
        var clock = clock
        if let calendar { clock.calendar = calendar }
        return try GetCalendarMonthUseCase(payments: payments, records: records, clock: clock)
            .execute(.make(year, month))
    }

    @Test("CAL-01 · Días con pagos, hoy y total del mes actual")
    func currentMonth() throws {
        let october = try month(2026, 10)
        #expect(october.days.count == 31)
        #expect(october.today == 15)
        #expect(october.days.filter(\.hasPayments).map(\.day) == [1, 31])
        #expect(october.days[0].paidCount == 1)
        #expect(october.days[0].count == 1)  // el gimnasio se eliminó este mes y no se muestra
        #expect(october.total == Money(major: 530))
    }

    @Test("CAL-01 · La cuadrícula respeta el primer día de la semana de la región")
    func leadingDays() throws {
        // 1 de octubre de 2026 es jueves.
        var sundayFirst = calendar
        sundayFirst.firstWeekday = 1
        let fromSunday = try month(2026, 10, calendar: sundayFirst)
        #expect(fromSunday.leadingEmptyDays == 4)
        #expect(fromSunday.weekdaySymbols.count == 7)

        var mondayFirst = calendar
        mondayFirst.firstWeekday = 2
        let fromMonday = try month(2026, 10, calendar: mondayFirst)
        #expect(fromMonday.leadingEmptyDays == 3)
        #expect(fromMonday.weekdaySymbols.first == mondayFirst.veryShortStandaloneWeekdaySymbols[1])
    }

    @Test("PAG-07 · Un pago del 31 cae el 28 en febrero")
    func shortMonth() throws {
        let february = try month(2027, 2)
        #expect(february.days.count == 28)
        #expect(february.days.last?.count == 1)
        #expect(february.today == nil)
    }

    @Test("CAL-02 · Los meses pasados conservan pagos eliminados después de pagarlos; los futuros proyectan")
    func otherMonths() throws {
        let september = try month(2026, 9)
        #expect(september.days[0].count == 2)
        #expect(september.days[0].paidCount == 1)

        let december = try month(2026, 12)
        #expect(december.total == Money(major: 530))
        #expect(december.days.allSatisfy { $0.paidCount == 0 })
    }

    @Test("CAL-03 / CAL-04 · Detalle de hoy: editable, con progreso")
    func dayDetailCurrentMonth() throws {
        let detail = try GetDayDetailUseCase(payments: payments, records: records, clock: clock)
            .execute(try calendar.date(year: 2026, month: 10, day: 1))
        #expect(detail.isEditable)
        #expect(detail.items.map(\.name) == ["Renta"])
        #expect(detail.total == Money(major: 500))
        #expect(detail.progress == 1)
    }

    @Test("CAL-05 · Otros meses no son editables")
    func dayDetailOtherMonth() throws {
        let useCase = GetDayDetailUseCase(payments: payments, records: records, clock: clock)
        let past = try useCase.execute(try calendar.date(year: 2026, month: 9, day: 1))
        #expect(!past.isEditable)
        #expect(past.items.map(\.name) == ["Gimnasio", "Renta"])
        #expect(past.paidCount == 1)

        let future = try useCase.execute(try calendar.date(year: 2027, month: 2, day: 28))
        #expect(!future.isEditable)
        #expect(future.items.map(\.name) == ["Teléfono"])  // PAG-07
        #expect(future.progress == 0)
    }
}
