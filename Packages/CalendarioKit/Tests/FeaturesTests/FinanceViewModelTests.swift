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

    private func makeViewModel(
        scheduler: SpyReminderScheduler = SpyReminderScheduler(status: .authorized),
        authenticator: StubAuthenticator = StubAuthenticator()
    ) -> SettingsViewModel {
        SettingsViewModel(
            getSettings: GetSettingsUseCase(settings: settings),
            updateSalary: UpdateSalaryUseCase(settings: settings, observer: observer),
            changeCurrency: ChangeCurrencyUseCase(settings: settings, observer: observer),
            updateReminders: UpdateReminderSettingsUseCase(settings: settings, observer: observer),
            getReminderAuthorization: GetReminderAuthorizationUseCase(scheduler: scheduler),
            requestReminderPermission: RequestReminderPermissionUseCase(
                settings: settings, scheduler: scheduler, observer: observer),
            updateAppLock: UpdateAppLockSettingsUseCase(settings: settings),
            authenticator: authenticator,
            calendar: .testGregorian,
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

@Suite("NOT / SEG · Ajustes de recordatorios y bloqueo")
struct SystemSettingsViewModelTests {
    let settings = InMemorySettingsRepository(AppSettings(currency: .usd, hasCompletedOnboarding: true))
    let observer = SpyChangeObserver()

    private func makeViewModel(scheduler: SpyReminderScheduler, authenticator: StubAuthenticator) -> SettingsViewModel {
        SettingsViewModel(
            getSettings: GetSettingsUseCase(settings: settings),
            updateSalary: UpdateSalaryUseCase(settings: settings, observer: observer),
            changeCurrency: ChangeCurrencyUseCase(settings: settings, observer: observer),
            updateReminders: UpdateReminderSettingsUseCase(settings: settings, observer: observer),
            getReminderAuthorization: GetReminderAuthorizationUseCase(scheduler: scheduler),
            requestReminderPermission: RequestReminderPermissionUseCase(
                settings: settings, scheduler: scheduler, observer: observer),
            updateAppLock: UpdateAppLockSettingsUseCase(settings: settings),
            authenticator: authenticator,
            calendar: .testGregorian)
    }

    @Test("NOT-02 / NOT-05 · Cambiar la hora y apagar los avisos los reprograma")
    func reminders() async throws {
        let viewModel = makeViewModel(
            scheduler: SpyReminderScheduler(status: .authorized), authenticator: StubAuthenticator())
        viewModel.load()
        #expect(viewModel.reminders == ReminderSettings())  // NOT-01: 8:00 y activados

        let nineThirty = try Calendar.testGregorian.date(year: 2001, month: 1, day: 1, hour: 21, minute: 30)
        viewModel.setReminderTime(nineThirty)
        #expect(settings.stored.reminders.hour == 21)
        #expect(settings.stored.reminders.minute == 30)

        await viewModel.setRemindersEnabled(false)
        #expect(!settings.stored.reminders.isEnabled)
        #expect(observer.changes == [.reminderSettings, .reminderSettings])
    }

    @Test("NOT-06 · Permiso denegado y petición desde Ajustes")
    func authorization() async {
        let denied = makeViewModel(scheduler: SpyReminderScheduler(status: .denied), authenticator: StubAuthenticator())
        await denied.refreshReminderAuthorization()
        #expect(denied.reminderAuthorization == .denied)

        let scheduler = SpyReminderScheduler(status: .notDetermined)
        let undetermined = makeViewModel(scheduler: scheduler, authenticator: StubAuthenticator())
        await undetermined.refreshReminderAuthorization()
        await undetermined.requestPermission()
        #expect(undetermined.reminderAuthorization == .authorized)
        #expect(await scheduler.requestCount == 1)
    }

    @Test("SEG-01 · Activar el bloqueo exige autenticarse; si falla, queda apagado")
    func lock() async {
        let authenticator = StubAuthenticator(result: .cancelled)
        let viewModel = makeViewModel(
            scheduler: SpyReminderScheduler(status: .authorized), authenticator: authenticator)
        viewModel.load()
        await viewModel.setLockEnabled(true)
        #expect(!settings.stored.appLock.isEnabled)

        authenticator.set(result: .success)
        await viewModel.setLockEnabled(true)
        #expect(settings.stored.appLock.isEnabled)
        #expect(viewModel.appLock.isEnabled)

        viewModel.setGracePeriod(.fiveMinutes)  // SEG-02
        #expect(settings.stored.appLock.gracePeriod == .fiveMinutes)

        await viewModel.setLockEnabled(false)
        #expect(!settings.stored.appLock.isEnabled)
        #expect(authenticator.authenticationCount == 2)  // apagarlo no pide autenticación
    }

    @Test("SEG-04 · Sin código en el iPhone no se puede activar")
    func lockWithoutPasscode() async {
        let viewModel = makeViewModel(
            scheduler: SpyReminderScheduler(status: .authorized),
            authenticator: StubAuthenticator(availability: .passcodeNotSet))
        viewModel.load()
        await viewModel.setLockEnabled(true)
        #expect(viewModel.showsPasscodeRequiredAlert)
        #expect(!settings.stored.appLock.isEnabled)
    }

    @Test("Editar un ajuste no borra el salario que se está escribiendo")
    func keepsSalaryDraft() async {
        let viewModel = makeViewModel(
            scheduler: SpyReminderScheduler(status: .authorized), authenticator: StubAuthenticator())
        viewModel.load()
        viewModel.salaryText = "1500"
        await viewModel.setRemindersEnabled(false)
        #expect(viewModel.salaryText == "1500")
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
