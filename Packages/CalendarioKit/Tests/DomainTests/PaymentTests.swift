import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("ADR-07 · Pago activo en un mes", .tags(.payments, .history))
struct PaymentActivityTests {
    let calendar = Calendar.testGregorian

    @Test("S-07 · Cuenta desde el mes de creación aunque su día ya haya pasado")
    func activeFromCreationMonth() throws {
        let payment = Payment.fixture(day: 1, createdAt: try calendar.date(year: 2026, month: 10, day: 20))
        #expect(!payment.isActive(in: try .make(2026, 9), calendar: calendar))
        #expect(payment.isActive(in: try .make(2026, 10), calendar: calendar))
        #expect(payment.isActive(in: try .make(2027, 3), calendar: calendar))
    }

    @Test("Un pago eliminado deja de existir desde el mes en que se eliminó")
    func inactiveFromDeletionMonth() throws {
        let payment = Payment.fixture(
            createdAt: try calendar.date(year: 2026, month: 6, day: 1),
            deletedAt: try calendar.date(year: 2026, month: 9, day: 15))
        #expect(payment.isActive(in: try .make(2026, 8), calendar: calendar))
        #expect(!payment.isActive(in: try .make(2026, 9), calendar: calendar))
        #expect(!payment.isActive(in: try .make(2026, 10), calendar: calendar))
    }

    @Test("PAG-03 · La quincena se deriva del día")
    func fortnight() throws {
        let created = try calendar.date(year: 2026, month: 1, day: 1)
        #expect(Payment.fixture(day: 15, createdAt: created).fortnight == .first)
        #expect(Payment.fixture(day: 16, createdAt: created).fortnight == .second)
    }

    @Test("MAR-04 · La instantánea copia nombre, monto y categoría")
    func snapshot() throws {
        let markedAt = try calendar.date(year: 2026, month: 10, day: 5)
        let payment = Payment.fixture(name: "Luz", amount: Money(major: 80), category: .utilities, createdAt: markedAt)
        let record = PaymentRecord(snapshotOf: payment, period: try .make(2026, 10), markedAt: markedAt)
        #expect(record.paymentID == payment.id)
        #expect(record.name == "Luz")
        #expect(record.amount == Money(major: 80))
        #expect(record.category == .utilities)
        #expect(record.period == (try .make(2026, 10)))
        #expect(record.markedAt == markedAt)
    }
}
