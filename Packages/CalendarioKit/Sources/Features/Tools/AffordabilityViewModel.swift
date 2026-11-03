import Domain
import Foundation
import Observation

/// ¿Puedo costearlo? (HER-01 a HER-03). Se recalcula al cambiar el monto o el tipo.
@Observable
public final class AffordabilityViewModel {
    public var amountText = "" {
        didSet { if amountText != oldValue { evaluate() } }
    }
    public var kind: ExpenseKind = .need {
        didSet { if kind != oldValue { evaluate() } }
    }
    /// `loaded(nil)`: sin salario configurado (S-05).
    public private(set) var state: LoadState<AffordabilityResult?> = .idle

    private let evaluateAffordability: EvaluateAffordabilityUseCase
    private let locale: Locale

    public init(evaluateAffordability: EvaluateAffordabilityUseCase, locale: Locale = .autoupdatingCurrent) {
        self.evaluateAffordability = evaluateAffordability
        self.locale = locale
    }

    /// HER-01: monto del nuevo gasto mensual; `nil` mientras el campo no tenga un monto válido.
    public var newExpense: Money? {
        guard let decimal = AmountInput.decimal(amountText, locale: locale),
            let money = Money(validatingInput: decimal), money > .zero
        else { return nil }
        return money
    }

    public var hasSalary: Bool {
        if case .loaded(let result) = state { result != nil } else { false }
    }

    /// HER-02: el resultado solo se muestra con un monto válido.
    public var result: AffordabilityResult? {
        guard newExpense != nil, case .loaded(let result) = state else { return nil }
        return result
    }

    public func load() { evaluate() }

    private func evaluate() {
        do {
            state = .loaded(try evaluateAffordability.execute(newExpense: newExpense ?? .zero, kind: kind))
        } catch {
            state = .failed(UserFacingError(error))
        }
    }
}
