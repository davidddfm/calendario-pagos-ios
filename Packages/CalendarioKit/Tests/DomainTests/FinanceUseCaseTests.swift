import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("DAS / HER · Casos de uso de finanzas", .tags(.dashboard, .tools))
struct FinanceUseCaseTests {
    let calendar = Calendar.testGregorian
    let clock: FixedClock
    let payments: InMemoryPaymentRepository
    let rent: Payment
    let gym: Payment

    init() throws {
        clock = FixedClock(now: try calendar.date(year: 2026, month: 10, day: 15))
        let created = try calendar.date(year: 2026, month: 1, day: 1)
        rent = Payment.fixture(
            name: "Renta", amount: Money(major: 500), day: 1, category: .utilities, createdAt: created)
        gym = Payment.fixture(
            name: "Gimnasio", amount: Money(major: 100), day: 20, category: .wellbeing, createdAt: created)
        let deleted = Payment.fixture(
            name: "Antiguo", amount: Money(major: 999), createdAt: created,
            deletedAt: try calendar.date(year: 2026, month: 9, day: 1))
        let future = Payment.fixture(
            name: "Futuro", amount: Money(major: 999), createdAt: try calendar.date(year: 2026, month: 11, day: 1))
        payments = InMemoryPaymentRepository([rent, gym, deleted, future])
    }

    private func settings(salary: Money?) -> InMemorySettingsRepository {
        InMemorySettingsRepository(AppSettings(currency: .eur, monthlySalary: salary, hasCompletedOnboarding: true))
    }

    @Test("DAS-01 a DAS-04 · El Dashboard usa solo los pagos activos del mes")
    func dashboard() throws {
        let summary = try GetDashboardUseCase(
            payments: payments, settings: settings(salary: Money(major: 1_000)), clock: clock
        ).execute()
        #expect(summary.totalMonthly == Money(major: 600))
        #expect(summary.availability?.available == Money(major: 400))
        #expect(summary.availability?.level == .warning)

        let withoutSalary = try GetDashboardUseCase(payments: payments, settings: settings(salary: nil), clock: clock)
            .execute()
        #expect(withoutSalary.availability == nil)
        #expect(withoutSalary.categoryShares.map(\.category) == [.utilities, .wellbeing])
    }

    @Test("HER-01 a HER-03 · ¿Puedo costearlo? necesita salario")
    func affordability() throws {
        let useCase = EvaluateAffordabilityUseCase(
            payments: payments, settings: settings(salary: Money(major: 1_000)), clock: clock)
        let result = try #require(try useCase.execute(newExpense: Money(major: 100), kind: .want))
        #expect(result.needs == Money(major: 500))
        #expect(result.wants == Money(major: 200))
        #expect(result.savings == Money(major: 300))
        #expect(result.light == .green)

        let noSalary = EvaluateAffordabilityUseCase(payments: payments, settings: settings(salary: nil), clock: clock)
        #expect(try noSalary.execute(newExpense: Money(major: 100), kind: .need) == nil)
    }

    @Test("HER-04 a HER-06 · Fugas sin salario")
    func leaks() throws {
        let report = try GetLeakReportUseCase(payments: payments, clock: clock).execute()
        #expect(report.items.map(\.name) == ["Renta", "Gimnasio"])
        #expect(report.annualTotal == Money(major: 7_200))
    }

    @Test("HER-07 · Plan 50/30/20 solo con salario")
    func budgetPlan() {
        #expect(GetBudgetPlanUseCase(settings: settings(salary: nil)).execute() == nil)
        let plan = GetBudgetPlanUseCase(settings: settings(salary: Money(major: 1_000))).execute()
        #expect(plan == BudgetPlan(needs: Money(major: 500), wants: Money(major: 300), savings: Money(major: 200)))
    }

    @Test("HER-08 / MND-04 / S-10 · Exporta los pagos activos, ordenados, con la moneda y la fecha")
    func export() throws {
        let exporter = SpyExporter()
        let url = try ExportPaymentsUseCase(
            payments: payments, settings: settings(salary: nil), exporter: exporter, clock: clock
        ).execute()
        #expect(url == exporter.url)
        #expect(exporter.exported?.payments.map(\.name) == ["Renta", "Gimnasio"])
        #expect(exporter.exported?.currency == .eur)
        #expect(exporter.exported?.date == clock.now)
    }
}

@Suite("CFG-01 / DAS-05 / MND-03 · Ajustes", .tags(.settings))
struct SettingsUseCaseTests {
    let settings = InMemorySettingsRepository(AppSettings(currency: .usd, hasCompletedOnboarding: true))
    let observer = SpyChangeObserver()

    @Test("Guardar y quitar el salario avisa del cambio")
    func updateSalary() throws {
        let useCase = UpdateSalaryUseCase(settings: settings, observer: observer)
        try useCase.execute(SalaryValidator.maxSalary)
        #expect(settings.stored.monthlySalary == SalaryValidator.maxSalary)
        try useCase.execute(nil)
        #expect(settings.stored.monthlySalary == nil)
        #expect(observer.changes == [.salary, .salary])
    }

    @Test("DAS-05 · Un salario fuera de rango no se guarda", arguments: [0, -100, 999_999_901])
    func invalidSalary(minorUnits: Int64) {
        let useCase = UpdateSalaryUseCase(settings: settings, observer: observer)
        #expect(throws: SalaryValidationError.outOfRange) { try useCase.execute(Money(minorUnits: minorUnits)) }
        #expect(settings.stored.monthlySalary == nil)
        #expect(observer.changes.isEmpty)
    }

    @Test("MND-03 · Cambiar la moneda no convierte montos")
    func changeCurrency() throws {
        try settings.save(AppSettings(currency: .usd, monthlySalary: Money(major: 2_000), hasCompletedOnboarding: true))
        let useCase = ChangeCurrencyUseCase(settings: settings, observer: observer)
        try useCase.execute(.eur)
        #expect(settings.stored.currency == .eur)
        #expect(settings.stored.monthlySalary == Money(major: 2_000))
        try useCase.execute(.eur)
        #expect(observer.changes == [.currency])
        #expect(GetSettingsUseCase(settings: settings).execute() == settings.stored)
    }
}

private final class SpyExporter: PaymentsExporting {
    let url = URL(filePath: "/tmp/pagos.csv")
    private(set) var exported: (payments: [Payment], currency: Currency, date: Date)?

    func export(_ payments: [Payment], currency: Currency, date: Date) throws -> URL {
        exported = (payments, currency, date)
        return url
    }
}
