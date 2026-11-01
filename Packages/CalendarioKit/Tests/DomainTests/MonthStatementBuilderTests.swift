import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("MAR / HIS · Estado mensual", .tags(.history))
struct MonthStatementBuilderTests {
    let calendar = Calendar.testGregorian

    private func created() throws -> Date { try calendar.date(year: 2026, month: 1, day: 1) }

    @Test("MAR-03 · Un mes sin registros tiene todos los pagos pendientes")
    func newMonthStartsPending() throws {
        let rent = Payment.fixture(name: "Renta", day: 1, createdAt: try created())
        let october = try YearMonth.make(2026, 10)
        let record = PaymentRecord(snapshotOf: rent, period: october, markedAt: try created())

        let octoberStatement = MonthStatementBuilder.build(
            period: october, payments: [rent], records: [record], calendar: calendar)
        let november = MonthStatementBuilder.build(
            period: october.adding(months: 1), payments: [rent], records: [record], calendar: calendar)

        #expect(octoberStatement.paid.map(\.id) == [rent.id])
        #expect(november.pending.map(\.id) == [rent.id])
        #expect(november.paid.isEmpty)
    }

    @Test("MAR-04 / MAR-05 · Un pago editado tras marcarlo conserva la instantánea")
    func editedAfterPayingKeepsSnapshot() throws {
        let period = try YearMonth.make(2026, 10)
        var gym = Payment.fixture(
            name: "Gimnasio", amount: Money(major: 30), category: .wellbeing, createdAt: try created())
        let record = PaymentRecord(snapshotOf: gym, period: period, markedAt: try created())
        gym.name = "Gym"
        gym.amount = Money(major: 45)
        gym.category = .expenses

        let item = try #require(
            MonthStatementBuilder.build(period: period, payments: [gym], records: [record], calendar: calendar)
                .items.first)

        #expect(item.name == "Gimnasio")
        #expect(item.category == .wellbeing)
        #expect(item.displayAmount == Money(major: 30))
        #expect(item.currentAmount == Money(major: 45))
        #expect(item.paidAmountDiffers)
    }

    @Test("S-02 · Un pendiente se muestra con los datos actuales")
    func pendingUsesCurrentData() throws {
        let period = try YearMonth.make(2026, 10)
        let payment = Payment.fixture(name: "Agua", amount: Money(major: 20), createdAt: try created())
        let item = try #require(
            MonthStatementBuilder.build(period: period, payments: [payment], records: [], calendar: calendar)
                .items.first)
        #expect(!item.isPaid)
        #expect(item.displayAmount == Money(major: 20))
        #expect(!item.paidAmountDiffers)
    }

    @Test("HIS-03 · Un pago eliminado después de pagarlo sigue en su mes")
    func deletedAfterPayingStaysInMonth() throws {
        let september = try YearMonth.make(2026, 9)
        let payment = Payment.fixture(
            name: "Netflix", amount: Money(major: 15), day: 20, createdAt: try created(),
            deletedAt: try calendar.date(year: 2026, month: 9, day: 25))
        let record = PaymentRecord(snapshotOf: payment, period: september, markedAt: try created())

        let statement = MonthStatementBuilder.build(
            period: september, payments: [payment], records: [record], calendar: calendar)

        let item = try #require(statement.items.first)
        #expect(statement.items.count == 1)
        #expect(item.isPaid)
        #expect(item.currentAmount == nil)
        #expect(item.scheduledDay == 20)
        #expect(item.fortnight == .second)
        #expect(!item.paidAmountDiffers)
    }

    @Test("Un registro sin pago en el almacén se ubica el día 1 y no cierra la app")
    func orphanRecord() throws {
        let period = try YearMonth.make(2026, 10)
        let ghost = Payment.fixture(name: "Huérfano", createdAt: try created())
        let record = PaymentRecord(snapshotOf: ghost, period: period, markedAt: try created())

        let statement = MonthStatementBuilder.build(period: period, payments: [], records: [record], calendar: calendar)
        #expect(statement.items.map(\.effectiveDay) == [1])
        #expect(statement.paidTotal == ghost.amount)
    }

    @Test("Los registros de otros meses se ignoran")
    func ignoresOtherPeriods() throws {
        let payment = Payment.fixture(createdAt: try created())
        let record = PaymentRecord(snapshotOf: payment, period: try .make(2026, 9), markedAt: try created())
        let statement = MonthStatementBuilder.build(
            period: try .make(2026, 10), payments: [payment], records: [record], calendar: calendar)
        #expect(statement.pending.count == 1)
    }

    @Test("PAG-07 · Orden por día efectivo y luego por nombre")
    func sorting() throws {
        let created = try created()
        let payments = [
            Payment.fixture(name: "zeta", day: 31, createdAt: created),
            Payment.fixture(name: "Beta", day: 28, createdAt: created),
            Payment.fixture(name: "alfa", day: 28, createdAt: created),
            Payment.fixture(name: "Primero", day: 2, createdAt: created),
        ]
        let statement = MonthStatementBuilder.build(
            period: try .make(2026, 2), payments: payments, records: [], calendar: calendar)
        #expect(statement.items.map(\.name) == ["Primero", "alfa", "Beta", "zeta"])
        #expect(statement.items.map(\.effectiveDay) == [2, 28, 28, 28])
        #expect(statement.items(onEffectiveDay: 28).count == 3)
    }

    @Test("HIS-01 · Total pagado y cumplimiento")
    func totalsAndCompliance() throws {
        let period = try YearMonth.make(2026, 10)
        let created = try created()
        let a = Payment.fixture(amount: Money(major: 100), day: 5, createdAt: created)
        let b = Payment.fixture(amount: Money(major: 50), day: 20, createdAt: created)
        let c = Payment.fixture(amount: Money(major: 25), day: 25, createdAt: created)
        let records = [a, b].map { PaymentRecord(snapshotOf: $0, period: period, markedAt: created) }

        let statement = MonthStatementBuilder.build(
            period: period, payments: [a, b, c], records: records, calendar: calendar)

        #expect(statement.paidTotal == Money(major: 150))
        #expect(statement.total == Money(major: 175))
        #expect(statement.compliance == 2.0 / 3.0)
        #expect(statement.items(in: .first).map(\.id) == [a.id])
        #expect(statement.items(in: .second).map(\.id) == [b.id, c.id])
    }

    @Test func emptyMonthHasZeroCompliance() throws {
        let statement = MonthStatementBuilder.build(
            period: try .make(2026, 10), payments: [], records: [], calendar: calendar)
        #expect(statement.compliance == 0)
        #expect(statement.paidTotal == .zero)
    }

    @Test("Registros duplicados del mismo pago no duplican el item")
    func duplicateRecords() throws {
        let period = try YearMonth.make(2026, 10)
        let payment = Payment.fixture(createdAt: try created())
        let records = (0..<2).map { _ in PaymentRecord(snapshotOf: payment, period: period, markedAt: Date.distantPast)
        }
        let statement = MonthStatementBuilder.build(
            period: period, payments: [payment], records: records, calendar: calendar)
        #expect(statement.items.count == 1)
    }
}
