import Domain
import Observation

/// MND-01: elección de moneda antes de registrar nada.
@Observable
public final class OnboardingViewModel {
    public var selectedCurrency: Currency?
    public private(set) var error: UserFacingError?

    private let completeOnboarding: CompleteOnboardingUseCase

    public init(completeOnboarding: CompleteOnboardingUseCase) {
        self.completeOnboarding = completeOnboarding
    }

    public var canContinue: Bool { selectedCurrency != nil }

    public func complete() {
        guard let selectedCurrency else { return }
        do {
            try completeOnboarding.execute(currency: selectedCurrency)
            error = nil
        } catch {
            self.error = UserFacingError(error)
        }
    }

    public func dismissError() { error = nil }
}
