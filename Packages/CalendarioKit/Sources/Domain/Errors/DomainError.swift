import Foundation

/// Errores de los casos de uso que no son de validación de formulario.
public enum DomainError: Error, Equatable, Sendable {
    /// MAR-02: no se puede marcar un mes que aún no empieza.
    case futurePeriod
    case paymentNotFound
    /// El pago no existía en el mes indicado (creado después o eliminado antes).
    case paymentNotInPeriod
    /// PAG-01: los casos de uso vuelven a validar antes de persistir (defensa en profundidad, §5.4).
    case invalidPayment([PaymentValidationError])
    /// El calendario no pudo construir una fecha del mes (no ocurre con el calendario gregoriano).
    case invalidDate
    /// NOT-02: hora fuera de 0–23 o minuto fuera de 0–59.
    case invalidReminderTime
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .futurePeriod: String(localized: "No se pueden marcar pagos de meses futuros.", bundle: .module)
        case .paymentNotFound: String(localized: "El pago ya no existe.", bundle: .module)
        case .paymentNotInPeriod: String(localized: "El pago no existía en ese mes.", bundle: .module)
        case .invalidPayment(let errors):
            errors.first?.errorDescription ?? String(localized: "Revisa los datos del pago.", bundle: .module)
        case .invalidDate: String(localized: "No se pudo mostrar esa fecha.", bundle: .module)
        case .invalidReminderTime: String(localized: "Elige una hora válida para el aviso.", bundle: .module)
        }
    }
}
