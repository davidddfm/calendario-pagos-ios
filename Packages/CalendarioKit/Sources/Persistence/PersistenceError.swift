import Domain
import Foundation

/// Envuelve los errores de SwiftData; el detalle técnico solo va al registro (§14.3).
public enum PersistenceError: Error, Equatable, Sendable {
    case storeUnavailable
    case fetchFailed
    case saveFailed
}

extension PersistenceError: UserPresentableError {
    public var errorDescription: String? {
        switch self {
        case .storeUnavailable: String(localized: "No se pudieron abrir tus datos.", bundle: .module)
        case .fetchFailed: String(localized: "No se pudieron leer tus pagos.", bundle: .module)
        case .saveFailed: String(localized: "No se pudo guardar el cambio. Inténtalo de nuevo.", bundle: .module)
        }
    }
}
