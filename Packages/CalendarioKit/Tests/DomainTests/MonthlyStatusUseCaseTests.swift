import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("MAR-01 a MAR-04 / HIS-04 · Marcar como pagado", .tags(.history))
struct TogglePaymentPaidUseCaseTests {
    let calendar = Calendar.testGregorian
    let payments = InMemoryPaymentRepository()
    let records = InMemoryPaymentRecordRepository()
    let observer = SpyChangeObserver()
    let clock: FixedClock
    let payment: Payment

    init() throws {
        clock = FixedClock(now: try calendar.date(year: 2026, month: 10, day: 15))
        payment = Payment.fixture(
            name: "Luz", amount: Money(major: 80), createdAt: try calendar.date(year: 2026, month: 6, day: 1))
        try payments.insert(payment)
    }

    private var useCase: TogglePaymentPaidUseCase {
        TogglePaymentPaidUseCase(payments: payments, records: records, clock: clock, observer: observer)
    }

    @Test("Marcar guarda la instantánea en el mes actual y desmarcar la borra")
    func toggleCurrentMonth() throws {
        #expect(try useCase.execute(paymentID: payment.id))
        let record = try #require(records.stored.first)
        #expect(record.period == (try .make(2026, 10)))
        #expect(record.name == "Luz")
        #expect(record.amount == Money(major: 80))
        #expect(record.markedAt == clock.now)

        #expect(try !useCase.execute(paymentID: payment.id))
        #expect(records.stored.isEmpty)
        #expect(observer.changes == [.paymentStatus, .paymentStatus])
    }

    @Test("HIS-04 · Se puede corregir un mes pasado")
    func pastMonth() throws {
        let august = try YearMonth.make(2026, 8)
        #expect(try useCase.execute(paymentID: payment.id, period: august))
        #expect(try records.record(paymentID: payment.id, period: august) != nil)
        #expect(try records.records(in: .make(2026, 10)).isEmpty)
    }

    @Test("No se marcan meses futuros")
    func futureMonth() {
        #expect(throws: DomainError.futurePeriod) {
            try useCase.execute(paymentID: payment.id, period: try .make(2026, 11))
        }
    }

    @Test("No se marca un mes en que el pago no existía")
    func notInPeriod() {
        #expect(throws: DomainError.paymentNotInPeriod) {
            try useCase.execute(paymentID: payment.id, period: try .make(2026, 5))
        }
        #expect(throws: DomainError.paymentNotFound) { try useCase.execute(paymentID: UUID()) }
    }

    @Test("Un pago eliminado después de pagarlo se puede desmarcar en su mes")
    func unmarkDeleted() throws {
        let september = try YearMonth.make(2026, 9)
        try useCase.execute(paymentID: payment.id, period: september)
        try payments.markDeleted(id: payment.id, at: try calendar.date(year: 2026, month: 9, day: 20))
        #expect(try !useCase.execute(paymentID: payment.id, period: september))
    }
}

@Suite("QUI-01 a QUI-04 · Detalle de quincena", .tags(.history))
struct FortnightDetailTests {
    let calendar = Calendar.testGregorian

    private func detail(_ fortnight: Fortnight, salary: Money?) throws -> FortnightDetail {
        let created = try calendar.date(year: 2026, month: 1, day: 1)
        let now = try calendar.date(year: 2026, month: 10, day: 20)
        let first = Payment.fixture(name: "Renta", amount: Money(major: 500), day: 1, createdAt: created)
        let second = Payment.fixture(name: "Luz", amount: Money(major: 80), day: 16, createdAt: created)
        let third = Payment.fixture(name: "Agua", amount: Money(major: 20), day: 31, createdAt: created)
        let record = PaymentRecord(
            snapshotOf: Payment.fixture(id: second.id, name: "Luz", amount: Money(major: 70), createdAt: created),
            period: try .make(2026, 10), markedAt: now)
        return try GetFortnightDetailUseCase(
            payments: InMemoryPaymentRepository([first, second, third]),
            records: InMemoryPaymentRecordRepository([record]),
            settings: InMemorySettingsRepository(AppSettings(currency: .usd, monthlySalary: salary)),
            clock: FixedClock(now: now)
        ).execute(fortnight)
    }

    @Test("QUI-02 · Saldo = salario ÷ 2 − total de la quincena (con el monto pagado registrado)")
    func remaining() throws {
        let second = try detail(.second, salary: Money(major: 1_000))
        #expect(second.items.map(\.name) == ["Luz", "Agua"])
        #expect(second.total == Money(major: 90))
        #expect(second.remaining == Money(major: 410))

        let first = try detail(.first, salary: Money(major: 1_000))
        #expect(first.remaining == Money(major: 0))
    }

    @Test("S-09 · La mitad del salario se trunca a centavos")
    func truncation() throws {
        let first = try detail(.first, salary: Money(minorUnits: 100_001))
        #expect(first.remaining == Money(minorUnits: 50_000 - 50_000))
    }

    @Test("QUI-04 · Sin salario no hay saldo, pero sí la lista")
    func noSalary() throws {
        let second = try detail(.second, salary: nil)
        #expect(second.remaining == nil)
        #expect(second.items.count == 2)
    }
}

@Suite("HIS-01 / HIS-02 · Historial mensual", .tags(.history))
struct HistoryOverviewTests {
    let calendar = Calendar.testGregorian

    @Test("S-04 · Meses desde el pago más antiguo hasta el actual, descendentes, con cumplimiento")
    func months() throws {
        let rent = Payment.fixture(
            name: "Renta", amount: Money(major: 500), day: 1, createdAt: try calendar.date(year: 2026, month: 8, day: 3)
        )
        let gym = Payment.fixture(
            name: "Gym", amount: Money(major: 30), day: 5, createdAt: try calendar.date(year: 2026, month: 9, day: 1))
        let records = [
            PaymentRecord(snapshotOf: rent, period: try .make(2026, 8), markedAt: .distantPast),
            PaymentRecord(snapshotOf: rent, period: try .make(2026, 9), markedAt: .distantPast),
            PaymentRecord(snapshotOf: gym, period: try .make(2026, 9), markedAt: .distantPast),
            PaymentRecord(snapshotOf: gym, period: try .make(2026, 10), markedAt: .distantPast),
        ]
        let overview = try GetHistoryOverviewUseCase(
            payments: InMemoryPaymentRepository([rent, gym]),
            records: InMemoryPaymentRecordRepository(records),
            clock: FixedClock(now: try calendar.date(year: 2026, month: 10, day: 10))
        ).execute()

        #expect(overview.months.map(\.period.month) == [10, 9, 8])
        #expect(overview.months.map(\.paidTotal) == [Money(major: 30), Money(major: 530), Money(major: 500)])
        #expect(overview.months.map(\.paidCount) == [1, 2, 1])
        #expect(overview.months.map(\.totalCount) == [2, 2, 1])
        #expect(overview.months.first?.compliance == 0.5)

        // HIS-02: 6 meses terminando en el actual, del más antiguo al más reciente; los vacíos en cero.
        #expect(overview.chart.map(\.period.month) == [5, 6, 7, 8, 9, 10])
        #expect(overview.chart.map(\.paidTotal.minorUnits) == [0, 0, 0, 50_000, 53_000, 3_000])
    }

    @Test func emptyWithoutPayments() throws {
        let overview = try GetHistoryOverviewUseCase(
            payments: InMemoryPaymentRepository(),
            records: InMemoryPaymentRecordRepository(),
            clock: FixedClock(now: try calendar.date(year: 2026, month: 10, day: 10))
        ).execute()
        #expect(overview.isEmpty)
        #expect(overview.chart.isEmpty)
    }

    @Test("HIS-03 · El estado de un mes separa pagados y pendientes")
    func monthStatement() throws {
        let created = try calendar.date(year: 2026, month: 1, day: 1)
        let a = Payment.fixture(name: "A", day: 1, createdAt: created)
        let b = Payment.fixture(name: "B", day: 2, createdAt: created)
        let september = try YearMonth.make(2026, 9)
        let statement = try GetMonthStatementUseCase(
            payments: InMemoryPaymentRepository([a, b]),
            records: InMemoryPaymentRecordRepository([
                PaymentRecord(snapshotOf: a, period: september, markedAt: created)
            ]),
            clock: FixedClock(now: try calendar.date(year: 2026, month: 10, day: 10))
        ).execute(september)
        #expect(statement.paid.map(\.name) == ["A"])
        #expect(statement.pending.map(\.name) == ["B"])
    }
}
