import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("PAG · Casos de uso de pagos", .tags(.payments))
struct PaymentUseCaseTests {
    let clock: FixedClock
    let payments = InMemoryPaymentRepository()
    let observer = SpyChangeObserver()

    init() throws {
        clock = FixedClock(now: try Calendar.testGregorian.date(year: 2026, month: 10, day: 20))
    }

    @Test("PAG-01 / PAG-02 · Crear guarda el nombre recortado y Gastos por defecto")
    func create() throws {
        let created = try CreatePaymentUseCase(payments: payments, clock: clock, observer: observer)
            .execute(PaymentDraft(name: "  Renta ", amount: Money(major: 500), dayOfMonth: 31))

        #expect(created.name == "Renta")
        #expect(created.category == .expenses)
        #expect(created.fortnight == .second)
        #expect(created.createdAt == clock.now)
        #expect(try payments.payment(id: created.id) == created)
        #expect(observer.changes == [.payments])
    }

    @Test("PAG-01 · Un borrador inválido no se guarda")
    func createInvalid() {
        let useCase = CreatePaymentUseCase(payments: payments, clock: clock, observer: observer)
        #expect(throws: DomainError.invalidPayment([.nameRequired, .amountRequired])) {
            try useCase.execute(PaymentDraft(name: "", amount: nil, dayOfMonth: 5))
        }
        #expect(payments.stored.isEmpty)
        #expect(observer.changes.isEmpty)
    }

    @Test("Editar cambia los datos y conserva la fecha de creación")
    func update() throws {
        let original = Payment.fixture(
            name: "Luz", day: 5, category: .utilities, createdAt: Date(timeIntervalSince1970: 0))
        try payments.insert(original)

        let updated = try UpdatePaymentUseCase(payments: payments, clock: clock, observer: observer)
            .execute(id: original.id, draft: PaymentDraft(name: "Luz CFE", amount: Money(major: 90), dayOfMonth: 18))

        #expect(updated.name == "Luz CFE")
        #expect(updated.amount == Money(major: 90))
        #expect(updated.dayOfMonth == 18)
        #expect(updated.category == .expenses)  // sin categoría elegida → Gastos
        #expect(updated.createdAt == original.createdAt)
        #expect(updated.updatedAt == clock.now)
        #expect(observer.changes == [.payments])
    }

    @Test("Editar un pago eliminado o inexistente falla")
    func updateMissing() throws {
        let deleted = Payment.fixture(
            createdAt: Date(timeIntervalSince1970: 0), deletedAt: Date(timeIntervalSince1970: 1))
        try payments.insert(deleted)
        let useCase = UpdatePaymentUseCase(payments: payments, clock: clock, observer: observer)
        let draft = PaymentDraft(name: "X", amount: Money(major: 1), dayOfMonth: 1)

        #expect(throws: DomainError.paymentNotFound) { try useCase.execute(id: deleted.id, draft: draft) }
        #expect(throws: DomainError.paymentNotFound) { try useCase.execute(id: UUID(), draft: draft) }
    }

    @Test("ADR-07 · Eliminar marca la fecha de borrado sin perder el pago")
    func delete() throws {
        let payment = Payment.fixture(createdAt: Date(timeIntervalSince1970: 0))
        try payments.insert(payment)

        try DeletePaymentUseCase(payments: payments, clock: clock, observer: observer).execute(id: payment.id)

        #expect(try payments.payment(id: payment.id)?.deletedAt == clock.now)
        #expect(try payments.payments(includingDeleted: false).isEmpty)
        #expect(observer.changes == [.payments])
        #expect(throws: DomainError.paymentNotFound) {
            try GetPaymentUseCase(payments: payments).execute(id: payment.id)
        }
    }

    @Test("MND-01 · Completar el onboarding guarda la moneda")
    func completeOnboarding() throws {
        let settings = InMemorySettingsRepository()
        try CompleteOnboardingUseCase(settings: settings, observer: observer).execute(currency: .eur)
        #expect(settings.stored.currency == .eur)
        #expect(settings.stored.hasCompletedOnboarding)
        #expect(observer.changes == [.currency])
    }
}

@Suite("PAG-06 a PAG-08 · Resumen de Inicio", .tags(.payments))
struct HomeSummaryTests {
    let calendar = Calendar.testGregorian

    @Test("PAG-06 / PAG-07 · Para hoy usa el día efectivo y las quincenas suman sus pagos")
    func summary() throws {
        let now = try calendar.date(year: 2026, month: 2, day: 28)
        let created = try calendar.date(year: 2026, month: 1, day: 1)
        let rent = Payment.fixture(name: "Renta", amount: Money(major: 500), day: 1, createdAt: created)
        let phone = Payment.fixture(name: "Teléfono", amount: Money(major: 30), day: 31, createdAt: created)
        let gym = Payment.fixture(name: "Gym", amount: Money(major: 20), day: 28, createdAt: created)

        let summary = try GetHomeSummaryUseCase(
            payments: InMemoryPaymentRepository([rent, phone, gym]),
            records: InMemoryPaymentRecordRepository(),
            clock: FixedClock(now: now)
        ).execute()

        #expect(Set(summary.todayItems.map(\.name)) == ["Gym", "Teléfono"])
        #expect(summary.fortnights.map(\.fortnight) == [.first, .second])
        #expect(summary.fortnights.map(\.total) == [Money(major: 500), Money(major: 50)])
        #expect(summary.fortnights.map(\.count) == [1, 2])
        #expect(summary.allItems.count == 3)
        #expect(!summary.isEmpty)
    }

    @Test("PAG-08 · Sin pagos el resumen está vacío y muestra las dos quincenas en cero")
    func empty() throws {
        let summary = try GetHomeSummaryUseCase(
            payments: InMemoryPaymentRepository(),
            records: InMemoryPaymentRecordRepository(),
            clock: FixedClock(now: try calendar.date(year: 2026, month: 10, day: 1))
        ).execute()
        #expect(summary.isEmpty)
        #expect(summary.fortnights.map(\.total) == [.zero, .zero])
    }

    @Test("Un pago pagado y luego eliminado este mes no aparece en Inicio")
    func hidesDeletedPaid() throws {
        let now = try calendar.date(year: 2026, month: 10, day: 20)
        let payment = Payment.fixture(
            day: 20, createdAt: try calendar.date(year: 2026, month: 1, day: 1), deletedAt: now)
        let record = PaymentRecord(snapshotOf: payment, period: try .make(2026, 10), markedAt: now)

        let summary = try GetHomeSummaryUseCase(
            payments: InMemoryPaymentRepository([payment]),
            records: InMemoryPaymentRecordRepository([record]),
            clock: FixedClock(now: now)
        ).execute()

        #expect(summary.isEmpty)
        #expect(summary.todayItems.isEmpty)
        #expect(summary.fortnights.map(\.total) == [.zero, .zero])
    }
}
