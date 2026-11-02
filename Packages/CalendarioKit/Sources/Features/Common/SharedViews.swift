import SwiftUI

/// Pantalla de error de carga con "Reintentar".
struct LoadFailedView: View {
    let error: UserFacingError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label {
                Text("No se pudieron cargar tus pagos", bundle: .module)
            } icon: {
                Image(systemName: "exclamationmark.triangle")
            }
        } description: {
            Text(verbatim: error.message)
        } actions: {
            Button(action: retry) {
                Text("Reintentar", bundle: .module)
            }
        }
    }
}

/// Carga y error encima de una `List` que nunca cambia de contenedor.
struct LoadStateOverlay<Value>: View {
    let state: LoadState<Value>
    let retry: () -> Void

    var body: some View {
        switch state {
        case .idle, .loading: ProgressView()
        case .failed(let error): LoadFailedView(error: error, retry: retry)
        case .loaded: EmptyView()
        }
    }
}

extension View {
    /// Alerta para errores de acciones (marcar, eliminar) que no reemplazan el contenido de la pantalla.
    func actionErrorAlert(error: UserFacingError?, dismiss: @escaping () -> Void) -> some View {
        alert(
            Text("No se pudo completar", bundle: .module),
            isPresented: Binding(get: { error != nil }, set: { if !$0 { dismiss() } }),
            presenting: error
        ) { _ in
        } message: { error in
            Text(verbatim: error.message)
        }
    }
}
