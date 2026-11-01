import Foundation

/// PAG-01 (§5.4). El validador devuelve todos los errores a la vez para mostrarlos junto a cada campo.
public enum PaymentValidationError: Error, Equatable, Sendable {
    case nameRequired
    case nameTooLong
    case amountRequired
    case amountOutOfRange
    case dayOutOfRange
}

extension PaymentValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .nameRequired: String(localized: "Escribe un nombre.", bundle: .module)
        case .nameTooLong: String(localized: "El nombre admite hasta 60 caracteres.", bundle: .module)
        case .amountRequired: String(localized: "Escribe un monto mayor que cero.", bundle: .module)
        case .amountOutOfRange: String(localized: "El monto máximo es 9,999,999.99.", bundle: .module)
        case .dayOutOfRange: String(localized: "Elige un día del 1 al 31.", bundle: .module)
        }
    }
}
