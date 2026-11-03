import Foundation
import Observation
import UserNotifications

/// NOT-09: tocar el aviso abre Inicio. Se asigna al arrancar para recibir también los toques en frío.
@Observable
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// La raíz lo entrega al router cuando la app no está bloqueada (SEG-03).
    var pendingLink: DeepLink?

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse
    ) async {
        let route = response.notification.request.content.userInfo["route"] as? String
        guard let link = route.flatMap(DeepLink.init(rawValue:)) else { return }
        await MainActor.run { pendingLink = link }
    }

    /// Con la app en primer plano el aviso también se muestra.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
