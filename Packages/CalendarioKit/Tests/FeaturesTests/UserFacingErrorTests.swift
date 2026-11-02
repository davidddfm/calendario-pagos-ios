import Domain
import Foundation
import Testing

@testable import Features

@Suite("§14.3 · Mensajes de error para el usuario")
struct UserFacingErrorTests {
    @Test func ownErrorsKeepTheirMessage() {
        #expect(UserFacingError(DomainError.paymentNotFound).message == "El pago ya no existe.")
    }

    @Test("Los errores de frameworks nunca se muestran tal cual")
    func frameworkErrorsAreGeneric() {
        let error = NSError(
            domain: "NSCocoaErrorDomain", code: 134_110, userInfo: [NSLocalizedDescriptionKey: "SQLite detalles"])
        #expect(UserFacingError(error).message == "Algo salió mal. Inténtalo de nuevo.")
    }
}
