import Foundation

/// Errores propios cuyo `errorDescription` sale del String Catalog y se puede mostrar al usuario (§14.3).
/// Los errores de frameworks nunca conforman: la UI muestra un mensaje genérico en su lugar.
public protocol UserPresentableError: LocalizedError {}

extension DomainError: UserPresentableError {}
extension PaymentValidationError: UserPresentableError {}
extension SalaryValidationError: UserPresentableError {}
