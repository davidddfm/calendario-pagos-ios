import Domain
import Foundation
import UserNotifications

/// NOT-01 a NOT-09 (§8.1). Es un `actor`: dos reconciliaciones seguidas nunca se intercalan.
public actor UserNotificationReminderScheduler: ReminderScheduling {
    static let prefix = "reminder."
    static let threadIdentifier = "daily-reminders"

    /// NOT-09: solo un identificador de ruta, nunca datos.
    private let route: String

    /// - Parameter route: valor de `DeepLink.today` que se guarda en `userInfo["route"]`.
    public init(route: String) {
        self.route = route
    }

    public func authorizationStatus() async -> ReminderAuthorization {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .authorized, .provisional, .ephemeral: .authorized
        case .denied: .denied
        @unknown default: .denied
        }
    }

    /// Sin `.badge`: la app no usa globos.
    public func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Reconciliación por diferencias. No usa `removeAllPendingNotificationRequests()`, que es asíncrona en otro hilo
    /// y podría borrar avisos recién añadidos.
    public func replaceAll(with plans: [ReminderPlan]) async throws {
        let center = UNUserNotificationCenter.current()
        let wanted = Set(plans.map(\.identifier))
        let obsolete = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(Self.prefix) && !wanted.contains($0) }
        center.removePendingNotificationRequests(withIdentifiers: obsolete)

        for plan in plans {
            let trigger = UNCalendarNotificationTrigger(dateMatching: plan.fireDate, repeats: false)
            // Un identificador existente reemplaza el aviso pendiente: la operación es idempotente.
            try await center.add(
                UNNotificationRequest(
                    identifier: plan.identifier, content: Self.content(for: plan, route: route),
                    trigger: trigger))
        }
    }

    public func removeAll() async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(Self.prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)
    }

    /// NOT-07: sin montos. NOT-09: sin categorías ni acciones.
    static func content(for plan: ReminderPlan, route: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = ReminderText.title()
        content.body = ReminderText.body(names: plan.pendingNames)
        content.sound = .default
        content.threadIdentifier = threadIdentifier
        content.userInfo = ["route": route]
        return content
    }
}
