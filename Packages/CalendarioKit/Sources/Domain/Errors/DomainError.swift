import Foundation

/// Errores de los casos de uso que no son de validación de formulario.
public enum DomainError: Error, Equatable, Sendable {
    /// MAR-02: no se puede marcar un mes que aún no empieza.
    case futurePeriod
    case paymentNotFound
    /// El pago no existía en el mes indicado (creado después o eliminado antes).
    case paymentNotInPeriod
}

extension DomainError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .futurePeriod: String(localized: "No se pueden marcar pagos de meses futuros.", bundle: .module)
        case .paymentNotFound: String(localized: "El pago ya no existe.", bundle: .module)
        case .paymentNotInPeriod: String(localized: "El pago no existía en ese mes.", bundle: .module)
        }
    }
}
