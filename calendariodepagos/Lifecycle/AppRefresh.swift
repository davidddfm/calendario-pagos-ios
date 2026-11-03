import BackgroundTasks
import os

/// NOT-04 / R-01: `BGAppRefreshTask` que solo renueva la ventana de avisos locales (directriz 2.5.4).
enum AppRefresh {
    static let identifier = "com.davidddfm.calendariodepagos.reminders"

    /// Se programa al pasar a segundo plano; el sistema decide cuándo ejecutarla.
    static func schedule() {
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = .now.addingTimeInterval(12 * 60 * 60)
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            Logger(subsystem: "com.davidddfm.calendariodepagos", category: "reminders")
                .error("No se pudo programar la renovación: \(String(describing: type(of: error)), privacy: .public)")
        }
    }
}
