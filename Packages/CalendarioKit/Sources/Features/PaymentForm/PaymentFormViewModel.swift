import Domain
import Foundation
import Observation

/// Crear y editar un pago (PAG-01 a PAG-04, CAT-02).
@Observable
public final class PaymentFormViewModel {
    public enum Mode: Hashable, Sendable {
        case create
        case edit(UUID)
    }

    public let mode: Mode
    // Solo un cambio real marca el campo como tocado: SwiftUI reescribe el mismo valor al mostrar el campo.
    public var name = "" {
        didSet { if name != oldValue { hasEditedName = true } }
    }
    public var amountText = "" {
        didSet { if amountText != oldValue { hasEditedAmount = true } }
    }
    public var dayOfMonth: Int
    /// §11.2: el selector arranca en "Gastos" (PAG-02).
    public var category: PaymentCategory = .default
    public var isConfirmingDeletion = false
    public private(set) var loadError: UserFacingError?
    public private(set) var actionError: UserFacingError?
    /// La vista se cierra cuando pasa a `true`.
    public private(set) var didFinish = false
    /// S-08 / NOT-06: explicación previa al permiso de notificaciones, tras guardar el primer pago.
    public private(set) var showsReminderPrompt = false

    private var hasEditedName = false
    private var hasEditedAmount = false
    private let createPayment: CreatePaymentUseCase
    private let updatePayment: UpdatePaymentUseCase
    private let deletePayment: DeletePaymentUseCase
    private let getPayment: GetPaymentUseCase
    private let shouldOfferReminderPermission: ShouldOfferReminderPermissionUseCase
    private let requestReminderPermission: RequestReminderPermissionUseCase
    private var offersReminderPermission = false
    private let locale: Locale

    public init(
        mode: Mode,
        defaultDay: Int,
        createPayment: CreatePaymentUseCase,
        updatePayment: UpdatePaymentUseCase,
        deletePayment: DeletePaymentUseCase,
        getPayment: GetPaymentUseCase,
        shouldOfferReminderPermission: ShouldOfferReminderPermissionUseCase,
        requestReminderPermission: RequestReminderPermissionUseCase,
        locale: Locale = .autoupdatingCurrent
    ) {
        self.mode = mode
        self.dayOfMonth = PaymentValidator.validDays.contains(defaultDay) ? defaultDay : 1
        self.createPayment = createPayment
        self.updatePayment = updatePayment
        self.deletePayment = deletePayment
        self.getPayment = getPayment
        self.shouldOfferReminderPermission = shouldOfferReminderPermission
        self.requestReminderPermission = requestReminderPermission
        self.locale = locale
    }

    public var isEditing: Bool { mode != .create }

    /// PAG-03: informativo, el usuario no la elige.
    public var fortnight: Fortnight { Fortnight(dayOfMonth: dayOfMonth) }

    public var draft: PaymentDraft {
        PaymentDraft(name: name, amount: amount, dayOfMonth: dayOfMonth, category: category)
    }

    public var validationErrors: [PaymentValidationError] {
        var errors = PaymentValidator.validate(draft)
        // Un número válido pero fuera de rango no es "monto vacío".
        if amount == nil, parsedDecimal != nil, let index = errors.firstIndex(of: .amountRequired) {
            errors[index] = .amountOutOfRange
        }
        return errors
    }

    public var canSave: Bool { validationErrors.isEmpty }

    /// Errores que se muestran junto al campo, solo después de que el usuario lo tocó.
    public var nameError: PaymentValidationError? {
        guard hasEditedName else { return nil }
        return validationErrors.first { $0 == .nameRequired || $0 == .nameTooLong }
    }

    public var amountError: PaymentValidationError? {
        guard hasEditedAmount else { return nil }
        return validationErrors.first { $0 == .amountRequired || $0 == .amountOutOfRange }
    }

    public func load() {
        guard case .edit(let id) = mode else { return }
        do {
            let payment = try getPayment.execute(id: id)
            name = payment.name
            amountText = AmountInput.text(payment.amount, locale: locale)
            dayOfMonth = payment.dayOfMonth
            category = payment.category
            hasEditedName = false
            hasEditedAmount = false
        } catch {
            loadError = UserFacingError(error)
        }
    }

    public func save() {
        guard canSave else { return }
        do {
            switch mode {
            case .create:
                try createPayment.execute(draft)
                if offersReminderPermission {
                    showsReminderPrompt = true
                    return
                }
            case .edit(let id): try updatePayment.execute(id: id, draft: draft)
            }
            didFinish = true
        } catch {
            actionError = UserFacingError(error)
        }
    }

    /// S-08: se consulta al abrir el formulario de alta, antes de guardar.
    public func prepareReminderPermission() async {
        guard mode == .create else { return }
        offersReminderPermission = await shouldOfferReminderPermission.execute()
    }

    /// NOT-06: "Activar recordatorios" muestra el diálogo del sistema; "Ahora no" no vuelve a preguntar.
    public func respondToReminderPrompt(accepted: Bool) async {
        showsReminderPrompt = false
        // El pago ya se guardó: un fallo al registrar la respuesta no debe impedir cerrar la hoja.
        _ = try? await requestReminderPermission.execute(accepted: accepted)
        didFinish = true
    }

    /// PAG-04: se llama desde el diálogo de confirmación.
    public func confirmDeletion() {
        guard case .edit(let id) = mode else { return }
        do {
            try deletePayment.execute(id: id)
            didFinish = true
        } catch {
            actionError = UserFacingError(error)
        }
    }

    public func dismissActionError() { actionError = nil }

    // MARK: - Monto

    private var parsedDecimal: Decimal? { AmountInput.decimal(amountText, locale: locale) }

    private var amount: Money? { parsedDecimal.flatMap(Money.init(validatingInput:)) }
}
