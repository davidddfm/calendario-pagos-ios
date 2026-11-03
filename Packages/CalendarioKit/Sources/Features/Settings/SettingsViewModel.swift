import Domain
import Foundation
import Observation

/// Ajustes de salario y moneda (CFG-01, DAS-05, MND-03). Recordatorios y bloqueo llegan en la iteración 5.
@Observable
public final class SettingsViewModel {
    /// Vacío = sin salario.
    public var salaryText = "" {
        didSet { if salaryText != oldValue { hasEditedSalary = true } }
    }
    public private(set) var savedSalary: Money?
    public private(set) var currency: Currency?
    /// MND-03: la moneda elegida espera la confirmación del usuario.
    public private(set) var pendingCurrency: Currency?
    public private(set) var actionError: UserFacingError?

    private var hasEditedSalary = false
    private let getSettings: GetSettingsUseCase
    private let updateSalary: UpdateSalaryUseCase
    private let changeCurrency: ChangeCurrencyUseCase
    private let locale: Locale

    public init(
        getSettings: GetSettingsUseCase,
        updateSalary: UpdateSalaryUseCase,
        changeCurrency: ChangeCurrencyUseCase,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.getSettings = getSettings
        self.updateSalary = updateSalary
        self.changeCurrency = changeCurrency
        self.locale = locale
    }

    public func load() {
        let settings = getSettings.execute()
        savedSalary = settings.monthlySalary
        currency = settings.currency
        salaryText = settings.monthlySalary.map { AmountInput.text($0, locale: locale) } ?? ""
        hasEditedSalary = false
    }

    // MARK: - Salario

    /// `.success(nil)` = campo vacío (sin salario).
    private var enteredSalary: Result<Money?, SalaryValidationError> {
        guard !salaryText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return .success(nil) }
        guard let decimal = AmountInput.decimal(salaryText, locale: locale),
            let money = Money(validatingInput: decimal), SalaryValidator.isValid(money)
        else { return .failure(.outOfRange) }
        return .success(money)
    }

    /// DAS-05: se muestra después de que el usuario edita el campo.
    public var salaryError: SalaryValidationError? {
        guard hasEditedSalary, case .failure(let error) = enteredSalary else { return nil }
        return error
    }

    public var canSaveSalary: Bool {
        guard case .success(let salary) = enteredSalary else { return false }
        return salary != savedSalary
    }

    public func saveSalary() {
        guard canSaveSalary, case .success(let salary) = enteredSalary else { return }
        perform { try updateSalary.execute(salary) }
    }

    /// §11.9: "Quitar salario".
    public func removeSalary() {
        perform { try updateSalary.execute(nil) }
    }

    // MARK: - Moneda

    public func requestCurrencyChange(to currency: Currency) {
        guard currency != self.currency else { return }
        pendingCurrency = currency
    }

    /// MND-03: solo tras la advertencia de que los montos no se convierten.
    public func confirmCurrencyChange() {
        guard let pendingCurrency else { return }
        self.pendingCurrency = nil
        perform { try changeCurrency.execute(pendingCurrency) }
    }

    public func cancelCurrencyChange() { pendingCurrency = nil }

    public func dismissActionError() { actionError = nil }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
            load()
        } catch {
            actionError = UserFacingError(error)
        }
    }
}
