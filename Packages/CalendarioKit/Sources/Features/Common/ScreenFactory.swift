/// Construye los ViewModels de cada pantalla. La implementa la raíz de composición de la app (§9.2).
public protocol ScreenFactory {
    func makeOnboardingViewModel() -> OnboardingViewModel
    func makeHomeViewModel() -> HomeViewModel
    func makePaymentFormViewModel(mode: PaymentFormViewModel.Mode) -> PaymentFormViewModel
}
