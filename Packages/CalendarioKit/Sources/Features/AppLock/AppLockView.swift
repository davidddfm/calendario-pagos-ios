import SwiftUI

/// SEG-03: mientras la app está bloqueada no se ve ningún dato.
public struct AppLockView: View {
    private let controller: AppLockController

    public init(controller: AppLockController) {
        self.controller = controller
    }

    public var body: some View {
        ContentUnavailableView {
            Label {
                Text("Calendario de Pagos está bloqueado", bundle: .module)
            } icon: {
                Image(systemName: "lock.fill")
            }
        } description: {
            Text("Usa Face ID, Touch ID o el código de tu iPhone para continuar.", bundle: .module)
        } actions: {
            Button {
                Task { await controller.unlock() }
            } label: {
                Text("Desbloquear", bundle: .module)
            }
            .buttonStyle(.borderedProminent)
            .disabled(controller.isAuthenticating)
            .accessibilityIdentifier("appLock.unlock")
        }
        // Primer intento automático; si se cancela, queda el botón.
        .task { await controller.unlock() }
    }
}
