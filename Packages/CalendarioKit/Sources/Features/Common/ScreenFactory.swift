import Domain

/// Construye los ViewModels de cada pantalla. La implementa la raíz de composición de la app (§9.2).
public protocol ScreenFactory {
    func makeOnboardingViewModel() -> OnboardingViewModel
    func makeHomeViewModel() -> HomeViewModel
    func makePaymentFormViewModel(mode: PaymentFormViewModel.Mode) -> PaymentFormViewModel
    func makeFortnightViewModel(fortnight: Fortnight) -> FortnightViewModel
    func makeHistoryViewModel() -> HistoryViewModel
    func makeHistoryMonthViewModel(period: YearMonth) -> HistoryMonthViewModel
    func makeDashboardViewModel() -> DashboardViewModel
    func makeSettingsViewModel() -> SettingsViewModel
    func makeAffordabilityViewModel() -> AffordabilityViewModel
    func makeLeakDetectorViewModel() -> LeakDetectorViewModel
    func makeBudgetPlanViewModel() -> BudgetPlanViewModel
    /// HER-08 / HER-10: archivo para `ShareLink` desde Inicio y Calendario.
    func makePaymentsCSVFile() -> PaymentsCSVFile
}
