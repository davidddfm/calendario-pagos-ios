import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("DAS · Dashboard financiero", .tags(.dashboard))
struct DashboardCalculatorTests {
    let created = Date(timeIntervalSince1970: 0)

    @Test(
        "DAS-01 · Verde hasta el 50 % del salario, naranja por encima",
        arguments: [
            (Int64(500_000), DashboardSummary.SpendingLevel.healthy),
            (500_001, .warning),
            (0, .healthy),
        ])
    func level(spentMinorUnits: Int64, expected: DashboardSummary.SpendingLevel) throws {
        let payments = [Payment.fixture(amount: Money(minorUnits: spentMinorUnits), createdAt: created)]
        let summary = DashboardCalculator.summary(salary: Money(major: 10_000), activePayments: payments)
        #expect(try #require(summary.availability).level == expected)
    }

    @Test("DAS-02 · Disponible negativo cuando los pagos superan el salario")
    func overdrawn() throws {
        let payments = [Payment.fixture(amount: Money(major: 1_200), createdAt: created)]
        let availability = try #require(
            DashboardCalculator.summary(salary: Money(major: 1_000), activePayments: payments).availability)
        #expect(availability.available == Money(major: -200))
        #expect(availability.isOverdrawn)
        #expect(availability.spentRatio == 1.2)
    }

    @Test("DAS-04 · Sin salario no hay disponible, pero sí categorías y fondo")
    func noSalary() {
        let payments = [Payment.fixture(amount: Money(major: 100), createdAt: created)]
        let summary = DashboardCalculator.summary(salary: nil, activePayments: payments)
        #expect(summary.availability == nil)
        #expect(summary.categoryShares.count == 1)
        #expect(summary.emergencyFund.threeMonths == Money(major: 300))
    }

    @Test("DAS-03 · Solo categorías con pagos, de mayor a menor")
    func categoryShares() {
        let payments = [
            Payment.fixture(amount: Money(major: 100), category: .utilities, createdAt: created),
            Payment.fixture(amount: Money(major: 200), category: .utilities, createdAt: created),
            Payment.fixture(amount: Money(major: 100), category: .loans, createdAt: created),
        ]
        let shares = DashboardCalculator.summary(salary: nil, activePayments: payments).categoryShares
        #expect(shares.map(\.category) == [.utilities, .loans])
        #expect(shares.map(\.total) == [Money(major: 300), Money(major: 100)])
        #expect(shares.map(\.share) == [0.75, 0.25])
    }

    @Test("Fondo de emergencia de 3, 6 y 12 meses")
    func emergencyFund() {
        let payments = [Payment.fixture(amount: Money(minorUnits: 12_345), createdAt: created)]
        let fund = DashboardCalculator.summary(salary: nil, activePayments: payments).emergencyFund
        #expect(fund.threeMonths.minorUnits == 37_035)
        #expect(fund.sixMonths.minorUnits == 74_070)
        #expect(fund.twelveMonths.minorUnits == 148_140)
    }

    @Test func noPayments() throws {
        let summary = DashboardCalculator.summary(salary: Money(major: 1_000), activePayments: [])
        #expect(summary.totalMonthly == .zero)
        #expect(summary.categoryShares.isEmpty)
        #expect(try #require(summary.availability).available == Money(major: 1_000))
    }
}
