import Domain
import Foundation
import Observation

/// Ajustes: salario, moneda, recordatorios y bloqueo (CFG-01, DAS-05, MND-03, NOT-02, NOT-05, NOT-06, SEG-01, SEG-02).
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
    public private(set) var reminders = ReminderSettings()
    /// NOT-06: `nil` hasta consultarlo.
    public private(set) var reminderAuthorization: ReminderAuthorization?
    public private(set) var appLock = AppLockSettings()
    /// SEG-04: no se puede activar el bloqueo sin código en el iPhone.
    public private(set) var showsPasscodeRequiredAlert = false

    private var hasEditedSalary = false
    private let getSettings: GetSettingsUseCase
    private let updateSalary: UpdateSalaryUseCase
    private let changeCurrency: ChangeCurrencyUseCase
    private let updateReminders: UpdateReminderSettingsUseCase
    private let getReminderAuthorization: GetReminderAuthorizationUseCase
    private let requestReminderPermission: RequestReminderPermissionUseCase
    private let updateAppLock: UpdateAppLockSettingsUseCase
    private let authenticator: any DeviceOwnerAuthenticating
    private let calendar: Calendar
    private let locale: Locale

    public init(
        getSettings: GetSettingsUseCase,
        updateSalary: UpdateSalaryUseCase,
        changeCurrency: ChangeCurrencyUseCase,
        updateReminders: UpdateReminderSettingsUseCase,
        getReminderAuthorization: GetReminderAuthorizationUseCase,
        requestReminderPermission: RequestReminderPermissionUseCase,
        updateAppLock: UpdateAppLockSettingsUseCase,
        authenticator: any DeviceOwnerAuthenticating,
        calendar: Calendar,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.getSettings = getSettings
        self.updateSalary = updateSalary
        self.changeCurrency = changeCurrency
        self.updateReminders = updateReminders
        self.getReminderAuthorization = getReminderAuthorization
        self.requestReminderPermission = requestReminderPermission
        self.updateAppLock = updateAppLock
        self.authenticator = authenticator
        self.calendar = calendar
        self.locale = locale
    }

    public func load() {
        let settings = getSettings.execute()
        savedSalary = settings.monthlySalary
        currency = settings.currency
        salaryText = settings.monthlySalary.map { AmountInput.text($0, locale: locale) } ?? ""
        hasEditedSalary = false
        reminders = settings.reminders
        appLock = settings.appLock
    }

    /// NOT-06: se relee al abrir Ajustes y al volver a la app.
    public func refreshReminderAuthorization() async {
        reminderAuthorization = await getReminderAuthorization.execute()
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
        perform(reloadingSalary: true) { try updateSalary.execute(salary) }
    }

    /// §11.9: "Quitar salario".
    public func removeSalary() {
        perform(reloadingSalary: true) { try updateSalary.execute(nil) }
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

    // MARK: - Recordatorios

    /// NOT-05. Activarlos sin haber decidido el permiso muestra el diálogo del sistema.
    public func setRemindersEnabled(_ isEnabled: Bool) async {
        perform { try updateReminders.execute(isEnabled: isEnabled, hour: reminders.hour, minute: reminders.minute) }
        if isEnabled, reminderAuthorization == .notDetermined {
            await requestPermission()
        }
    }

    /// NOT-02: el cambio se aplica desde el siguiente aviso.
    public var reminderTime: Date {
        calendar.date(
            bySettingHour: reminders.hour, minute: reminders.minute, second: 0,
            of: Date(timeIntervalSinceReferenceDate: 0)) ?? Date(timeIntervalSinceReferenceDate: 0)
    }

    public func setReminderTime(_ date: Date) {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute,
            hour != reminders.hour || minute != reminders.minute
        else { return }
        perform { try updateReminders.execute(isEnabled: reminders.isEnabled, hour: hour, minute: minute) }
    }

    public func requestPermission() async {
        do {
            reminderAuthorization = try await requestReminderPermission.execute()
        } catch {
            actionError = UserFacingError(error)
        }
    }

    // MARK: - Bloqueo

    public var biometry: DeviceBiometry { authenticator.biometry() }

    /// SEG-01: activarlo exige autenticarse primero; si falla, el interruptor queda apagado.
    public func setLockEnabled(_ isEnabled: Bool) async {
        guard isEnabled != appLock.isEnabled else { return }
        if isEnabled {
            switch authenticator.availability() {
            case .passcodeNotSet:
                showsPasscodeRequiredAlert = true
                return
            case .unavailable:
                return
            case .available:
                let reason = String(localized: "Confirma que eres tú para activar el bloqueo.", bundle: .module)
                guard await authenticator.authenticate(reason: reason) == .success else { return }
            }
        }
        var updated = appLock
        updated.isEnabled = isEnabled
        perform { try updateAppLock.execute(updated) }
    }

    /// SEG-02
    public func setGracePeriod(_ gracePeriod: LockGracePeriod) {
        guard gracePeriod != appLock.gracePeriod else { return }
        var updated = appLock
        updated.gracePeriod = gracePeriod
        perform { try updateAppLock.execute(updated) }
    }

    public func dismissPasscodeRequiredAlert() { showsPasscodeRequiredAlert = false }

    public func dismissActionError() { actionError = nil }

    /// Fuera de las acciones de salario no se pisa lo que el usuario esté escribiendo en ese campo.
    private func perform(reloadingSalary: Bool = false, _ action: () throws -> Void) {
        do {
            try action()
            if reloadingSalary {
                load()
            } else {
                let settings = getSettings.execute()
                currency = settings.currency
                reminders = settings.reminders
                appLock = settings.appLock
            }
        } catch {
            actionError = UserFacingError(error)
        }
    }
}
