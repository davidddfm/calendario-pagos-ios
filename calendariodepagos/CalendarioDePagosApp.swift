import Features
import SwiftUI
import UserNotifications
import os

@main
struct CalendarioDePagosApp: App {
    @State private var startup = AppStartup()
    @State private var notifications: NotificationDelegate

    init() {
        // NOT-09: el delegado se asigna antes de terminar el arranque para recibir el toque que abrió la app.
        let notifications = NotificationDelegate()
        UNUserNotificationCenter.current().delegate = notifications
        _notifications = State(initialValue: notifications)
    }

    var body: some Scene {
        WindowGroup {
            switch startup.state {
            case .ready(let container):
                RootView(container: container, notifications: notifications)
            case .failed(let message):
                StartupErrorView(message: message, retry: startup.start)
            }
        }
        // NOT-04 / R-01: solo renueva los avisos locales.
        .backgroundTask(.appRefresh(AppRefresh.identifier)) {
            await startup.refreshReminders()
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

    /// `BGAppRefreshTask`: reprograma la siguiente y renueva la ventana de avisos.
    func refreshReminders() async {
        AppRefresh.schedule()
        guard case .ready(let container) = state else { return }
        await container.reconcileReminders().value
    }

    private static var storage: AppContainer.Storage {
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-ui-testing") { return .uiTesting }
        #endif
        return .appGroup
    }
}
