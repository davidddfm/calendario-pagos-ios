import Domain
import Foundation

/// La UI nunca muestra `localizedDescription` de un framework (§14.3): solo mensajes propios del catálogo.
public struct UserFacingError: Error, Equatable, Identifiable {
    public let message: String

    public init(_ error: any Error) {
        if let presentable = error as? any UserPresentableError, let description = presentable.errorDescription {
            message = description
        } else {
            message = String(localized: "Algo salió mal. Inténtalo de nuevo.", bundle: .module)
        }
    }

    public var id: String { message }
}
