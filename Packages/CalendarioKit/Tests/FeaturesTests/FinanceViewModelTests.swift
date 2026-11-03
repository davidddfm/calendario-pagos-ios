import Domain
import Foundation
import TestSupport
import Testing

@testable import Features

@Suite("CFG / MND-03 · Ajustes")
struct SettingsViewModelTests {
    let settings = InMemorySettingsRepository(AppSettings(currency: .usd, hasCompletedOnboarding: true))
    let observer = SpyChangeObserver()
    let locale = Locale(identifier: "es_MX")

    private func makeViewModel() -> SettingsViewModel {
        SettingsViewModel(
            getSettings: GetSettingsUseCase(settings: settings),
            updateSalary: UpdateSalaryUseCase(settings: settings, observer: observer),
            changeCurrency: ChangeCurrencyUseCase(settings: settings, observer: observer),
            locale: locale)
    }

    @Test("CFG-01 · Guardar, editar y quitar el salario")
    func salary() {
        let viewModel = makeViewModel()
        viewModel.load()
        #expect(!viewModel.canSaveSalary)  // vacío y sin salario: nada que guardar

        viewModel.salaryText = "25000.50"
        #expect(viewModel.canSaveSalary)
        viewModel.saveSalary()
        #expect(settings.stored.monthlySalary == Money(minorUnits: 2_500_050))
        #expect(viewModel.salaryText == "25000.5")
        #expect(!viewModel.canSaveSalary)

        viewModel.removeSalary()
        #expect(settings.stored.monthlySalary == nil)
        #expect(viewModel.salaryText.isEmpty)
        #expect(observer.changes == [.salary, .salary])
    }

    @Test(
        "DAS-05 · Límite del salario",
        arguments: [("9999999", true), ("9999999.01", false), ("0", false), ("abc", false)])
    func salaryLimit(text: String, isValid: Bool) {
        let viewModel = makeViewModel()
        viewModel.load()
        #expect(viewModel.salaryError == nil)  // sin errores antes de editar
        viewModel.salaryText = text
        #expect(viewModel.canSaveSalary == isValid)
        #expect((viewModel.salaryError == nil) == isValid)
    }

    @Test("MND-03 · La moneda cambia solo tras confirmar")
    func currency() {
        let viewModel = makeViewModel()
        viewModel.load()

        viewModel.requestCurrencyChange(to: .usd)
        #expect(viewModel.pendingCurrency == nil)  // misma moneda: no se pregunta

        viewModel.requestCurrencyChange(to: .eur)
        #expect(viewModel.pendingCurrency == .eur)
        viewModel.cancelCurrencyChange()
        #expect(settings.stored.currency == .usd)

        viewModel.requestCurrencyChange(to: .eur)
        viewModel.confirmCurrencyChange()
        #expect(settings.stored.currency == .eur)
        #expect(viewModel.currency == .eur)
        #expect(viewModel.pendingCurrency == nil)
    }
}

@Suite("DAS / HER · ViewModels de finanzas")
struct FinanceViewModelTests {
    let settings = InMemorySettingsRepository(AppSettings(currency: .usd, hasCompletedOnboarding: true))
    let payments: InMemoryPaymentRepository
    let clock: FixedClock

    init() throws {
        let calendar = Calendar.testGregorian
        payments = InMemoryPaymentRepository([
            Payment.fixture(
                name: "Renta", amount: Money(major: 600), day: 1,
                createdAt: try calendar.date(year: 2026, month: 1, day: 1))
        ])
        clock = FixedClock(now: try calendar.date(year: 2026, month: 10, day: 10))
    }

    @Test("DAS-04 · El Dashboard carga sin salario y luego con salario")
    func dashboard() throws {
        let viewModel = DashboardViewModel(
            getDashboard: GetDashboardUseCase(payments: payments, settings: settings, clock: clock))
        viewModel.load()
        #expect(viewModel.state.value?.availability == nil)

        try settings.save(AppSettings(currency: .usd, monthlySalary: Money(major: 1_000), hasCompletedOnboarding: true))
        viewModel.load()
        #expect(viewModel.state.value?.availability?.available == Money(major: 400))
    }

    @Test("HER-01 a HER-03 · ¿Puedo costearlo? se recalcula al escribir y al cambiar el tipo")
    func affordability() throws {
        try settings.save(AppSettings(currency: .usd, monthlySalary: Money(major: 1_000), hasCompletedOnboarding: true))
        let viewModel = AffordabilityViewModel(
            evaluateAffordability: EvaluateAffordabilityUseCase(payments: payments, settings: settings, clock: clock),
            locale: Locale(identifier: "es_MX"))
        viewModel.load()
        #expect(viewModel.hasSalary)
        #expect(viewModel.result == nil)  // sin monto todavía

        viewModel.amountText = "280"
        #expect(viewModel.result?.needs == Money(major: 880))
        #expect(viewModel.result?.light == .yellow)  // ahorro: 1,000 − 880 = 120 → 12 %

        viewModel.kind = .want
        #expect(viewModel.result?.wants == Money(major: 280))
        #expect(viewModel.result?.needs == Money(major: 600))
    }

    @Test("S-05 · ¿Puedo costearlo? y Plan 50/30/20 piden salario; Fugas no")
    func withoutSalary() {
        let affordability = AffordabilityViewModel(
            evaluateAffordability: EvaluateAffordabilityUseCase(payments: payments, settings: settings, clock: clock))
        affordability.load()
        #expect(!affordability.hasSalary)

        let plan = BudgetPlanViewModel(getPlan: GetBudgetPlanUseCase(settings: settings))
        plan.load()
        guard case .loaded(nil) = plan.state else {
            Issue.record("Se esperaba el plan vacío")
            return
        }

        let leaks = LeakDetectorViewModel(getReport: GetLeakReportUseCase(payments: payments, clock: clock))
        leaks.load()
        #expect(leaks.state.value?.annualTotal == Money(major: 7_200))
    }
}
