import Features
import SwiftUI
import os

@main
struct CalendarioDePagosApp: App {
    @State private var startup = AppStartup()

    var body: some Scene {
        WindowGroup {
            switch startup.state {
            case .ready(let container):
                RootView(container: container)
            case .failed(let message):
                StartupErrorView(message: message, retry: startup.start)
            }
        }
    }
}

/// Crea la raíz de composición; un fallo se muestra y se puede reintentar (§7.2).
@Observable
final class AppStartup {
    enum State {
        case ready(AppContainer)
        case failed(String)
    }

    private(set) var state: State = .failed("")

    init() {
        start()
    }

    func start() {
        do {
            state = .ready(try AppContainer(storage: Self.storage))
        } catch {
            Logger(subsystem: "com.davidddfm.calendariodepagos", category: "startup")
                .error("Fallo al arrancar: \(String(describing: type(of: error)), privacy: .public)")
            state = .failed(UserFacingError(error).message)
        }
    }

    private static var storage: AppContainer.Storage {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") { return .uiTesting }
        #endif
        return .appGroup
    }
}
