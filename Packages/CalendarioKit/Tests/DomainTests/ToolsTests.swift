import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("HER-03 · Semáforo de ¿Puedo costearlo?", .tags(.tools))
struct AffordabilityTrafficLightTests {
    @Test(arguments: [
        (1_500_00, TrafficLight.green),  // 15 % exacto
        (1_499_99, .yellow),
        (1_000_00, .yellow),  // 10 % exacto
        (999_99, .red),
        (-1, .red),
    ])
    func lightForRemainingSavings(savingsMinorUnits: Int, expected: TrafficLight) {
        let result = AffordabilityCalculator.light(
            savings: Money(minorUnits: Int64(savingsMinorUnits)),
            salary: Money(minorUnits: 10_000_00),
            newExpense: Money(minorUnits: 100_00))
        #expect(result == expected)
    }

    @Test("Rojo si el gasto supera el ingreso")
    func expenseAboveSalary() {
        let result = AffordabilityCalculator.light(
            savings: Money(major: 5_000), salary: Money(major: 1_000), newExpense: Money(minorUnits: 1_000_01))
        #expect(result == .red)
    }
}

@Suite("HER-01 / HER-02 · ¿Puedo costearlo?", .tags(.tools))
struct AffordabilityEvaluationTests {
    let created = Date(timeIntervalSince1970: 0)

    var payments: [Payment] {
        [
            Payment.fixture(amount: Money(major: 400), category: .utilities, createdAt: created),
            Payment.fixture(amount: Money(major: 100), category: .wellbeing, createdAt: created),
            // Ahorros cuenta como ahorro restante (S-03).
            Payment.fixture(amount: Money(major: 200), category: .savings, createdAt: created),
        ]
    }

    @Test func needAddsToNeeds() {
        let result = AffordabilityCalculator.evaluate(
            salary: Money(major: 1_000), newExpense: Money(major: 300), kind: .need, activePayments: payments)
        #expect(result.needs == Money(major: 700))
        #expect(result.wants == Money(major: 100))
        #expect(result.savings == Money(major: 200))
        #expect(result.savingsShare == 0.2)
        #expect(result.light == .green)
    }

    @Test func wantAddsToWants() {
        let result = AffordabilityCalculator.evaluate(
            salary: Money(major: 1_000), newExpense: Money(major: 380), kind: .want, activePayments: payments)
        #expect(result.needs == Money(major: 400))
        #expect(result.wants == Money(major: 480))
        #expect(result.savings == Money(major: 120))
        #expect(result.light == .yellow)
    }

    @Test func overspendingIsRed() {
        let result = AffordabilityCalculator.evaluate(
            salary: Money(major: 1_000), newExpense: Money(major: 600), kind: .need, activePayments: payments)
        #expect(result.savings == Money(major: -100))
        #expect(result.light == .red)
    }
}

@Suite("HER-04 a HER-06 · Detector de fugas", .tags(.tools))
struct LeakDetectorTests {
    let created = Date(timeIntervalSince1970: 0)

    @Test func sortedByAmountWithAnnualCost() {
        let payments = [
            Payment.fixture(name: "Spotify", amount: Money(major: 10), createdAt: created),
            Payment.fixture(name: "Renta", amount: Money(major: 800), createdAt: created),
            Payment.fixture(name: "Apple", amount: Money(major: 10), createdAt: created),
        ]
        let report = LeakDetector.report(activePayments: payments)
        #expect(report.items.map(\.name) == ["Renta", "Apple", "Spotify"])
        #expect(report.items.map(\.annualCost) == [Money(major: 9_600), Money(major: 120), Money(major: 120)])
        #expect(report.annualTotal == Money(major: 9_840))
    }

    @Test func empty() {
        let report = LeakDetector.report(activePayments: [])
        #expect(report.items.isEmpty)
        #expect(report.annualTotal == .zero)
    }
}

@Suite("HER-07 · Plan 50/30/20", .tags(.tools))
struct BudgetPlanTests {
    @Test func exactSplit() {
        let plan = BudgetPlanCalculator.plan(salary: Money(major: 2_000))
        #expect(plan.needs == Money(major: 1_000))
        #expect(plan.wants == Money(major: 600))
        #expect(plan.savings == Money(major: 400))
    }

    @Test("El ahorro absorbe el redondeo")
    func roundingGoesToSavings() {
        let plan = BudgetPlanCalculator.plan(salary: Money(minorUnits: 100_001))
        #expect(plan.needs.minorUnits == 50_000)
        #expect(plan.wants.minorUnits == 30_000)
        #expect(plan.savings.minorUnits == 20_001)
        #expect(plan.needs + plan.wants + plan.savings == Money(minorUnits: 100_001))
    }
}
