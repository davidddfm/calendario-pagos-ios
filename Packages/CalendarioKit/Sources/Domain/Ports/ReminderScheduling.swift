/// NOT-06: estado del permiso de notificaciones.
public enum ReminderAuthorization: Sendable {
    case notDetermined, authorized, denied
}

/// Programa los avisos locales (§8.1). La implementación serializa las llamadas.
public protocol ReminderScheduling: Sendable {
    func authorizationStatus() async -> ReminderAuthorization
    /// Muestra el diálogo del sistema. Devuelve `true` si el usuario lo concede.
    func requestAuthorization() async -> Bool
    func replaceAll(with plans: [ReminderPlan]) async throws
    func removeAll() async
}
