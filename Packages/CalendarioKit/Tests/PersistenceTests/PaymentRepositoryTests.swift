import Domain
import Foundation
import SwiftData
import TestSupport
import Testing

@testable import Persistence

@MainActor
@Suite("§7 · Repositorio de pagos en SwiftData")
struct PaymentRepositoryTests {
    let container: ModelContainer
    let context: ModelContext
    let repository: SwiftDataPaymentRepository
    let created = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try PersistenceStack.makeContainer(inMemory: true)
        context = ModelContext(container)
        repository = SwiftDataPaymentRepository(context: context)
    }

    @Test func insertAndRead() throws {
        let payment = Payment.fixture(
            name: "Renta", amount: Money(minorUnits: 50_050), day: 31, category: .utilities, createdAt: created)
        try repository.insert(payment)

        #expect(try repository.payment(id: payment.id) == payment)
        #expect(try repository.payments(includingDeleted: false) == [payment])
    }

    @Test func update() throws {
        var payment = Payment.fixture(createdAt: created)
        try repository.insert(payment)
        payment.name = "Nuevo"
        payment.amount = Money(major: 7)
        payment.dayOfMonth = 3
        payment.category = .loans
        payment.updatedAt = created.addingTimeInterval(60)
        try repository.update(payment)

        #expect(try repository.payment(id: payment.id) == payment)
    }

    @Test("Actualizar o borrar un pago inexistente falla")
    func missing() {
        #expect(throws: DomainError.paymentNotFound) { try repository.update(Payment.fixture(createdAt: created)) }
        #expect(throws: DomainError.paymentNotFound) { try repository.markDeleted(id: UUID(), at: created) }
    }

    @Test("ADR-07 · El borrado es lógico")
    func softDelete() throws {
        let kept = Payment.fixture(name: "A", createdAt: created)
        let deleted = Payment.fixture(name: "B", createdAt: created)
        try repository.insert(kept)
        try repository.insert(deleted)
        try repository.markDeleted(id: deleted.id, at: created)

        #expect(try repository.payments(includingDeleted: false).map(\.id) == [kept.id])
        #expect(try repository.payments(includingDeleted: true).count == 2)
        #expect(try repository.payment(id: deleted.id)?.deletedAt == created)
    }

    @Test("§7.5 · Filas dañadas se omiten o corrigen sin cerrar la app")
    func corruptRows() throws {
        func row(name: String = "Ok", amount: Int64 = 100, day: Int = 1, category: String = "servicios")
            -> PaymentEntity
        {
            PaymentEntity(
                id: UUID(), name: name, amountMinorUnits: amount, dayOfMonth: day, categoryRaw: category,
                createdAt: created, updatedAt: created, deletedAt: nil)
        }
        let valid = row(name: "  ", category: "desconocida")
        for entity in [valid, row(day: 0), row(day: 32), row(amount: -5), row(amount: 0), row(amount: 1_000_000_000)] {
            context.insert(entity)
        }
        try context.save()

        let payments = try repository.payments(includingDeleted: true)
        #expect(payments.map(\.id) == [valid.id])
        #expect(payments.first?.name == "Sin nombre")
        #expect(payments.first?.category == .expenses)
    }
}

@MainActor
@Suite("§7 · Repositorio de registros en SwiftData", .tags(.history))
struct PaymentRecordRepositoryTests {
    let container: ModelContainer
    let context: ModelContext
    let repository: SwiftDataPaymentRecordRepository
    let markedAt = Date(timeIntervalSince1970: 1_800_000_000)

    init() throws {
        container = try PersistenceStack.makeContainer(inMemory: true)
        context = ModelContext(container)
        repository = SwiftDataPaymentRecordRepository(context: context)
    }

    private func record(_ payment: Payment, _ period: YearMonth, at date: Date? = nil) -> PaymentRecord {
        PaymentRecord(snapshotOf: payment, period: period, markedAt: date ?? markedAt)
    }

    @Test func insertReadAndDelete() throws {
        let payment = Payment.fixture(createdAt: markedAt)
        let october = try YearMonth.make(2026, 10)
        let original = record(payment, october)
        try repository.insert(original)

        #expect(try repository.record(paymentID: payment.id, period: october) == original)
        #expect(try repository.records(in: october) == [original])
        #expect(try repository.records(in: october.adding(months: 1)).isEmpty)

        try repository.delete(paymentID: payment.id, period: october)
        #expect(try repository.record(paymentID: payment.id, period: october) == nil)
    }

    @Test("Insertar dos veces el mismo pago y mes deja un solo registro")
    func idempotentInsert() throws {
        var payment = Payment.fixture(name: "Antes", createdAt: markedAt)
        let october = try YearMonth.make(2026, 10)
        try repository.insert(record(payment, october))
        payment.name = "Después"
        try repository.insert(record(payment, october, at: markedAt.addingTimeInterval(5)))

        let stored = try repository.records(in: october)
        #expect(stored.count == 1)
        #expect(stored.first?.name == "Después")
    }

    @Test func range() throws {
        let payment = Payment.fixture(createdAt: markedAt)
        for month in [8, 9, 10, 11] {
            try repository.insert(record(payment, try .make(2026, month)))
        }
        let result = try repository.records(from: try .make(2026, 9), through: try .make(2026, 10))
        #expect(result.map(\.period.month).sorted() == [9, 10])
    }

    @Test("§7.5 · Un registro con periodo inválido se omite")
    func corruptPeriod() throws {
        context.insert(
            PaymentRecordEntity(
                id: UUID(), paymentID: UUID(), periodKey: 202613, name: "x", amountMinorUnits: 1,
                categoryRaw: "gastos", markedAt: markedAt))
        try context.save()
        #expect(try repository.records(from: try .make(2026, 1), through: try .make(2027, 12)).isEmpty)
    }
}

extension Tag {
    @Tag static var history: Self
    @Tag static var settings: Self
}
