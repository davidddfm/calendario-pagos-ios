import SwiftUI

/// §7.2: si el almacén no abre, pantalla recuperable en lugar de cerrar la app.
struct StartupErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No se pudieron abrir tus datos", systemImage: "exclamationmark.triangle")
        } description: {
            Text(verbatim: message)
        } actions: {
            Button("Reintentar", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
