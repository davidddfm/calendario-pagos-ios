import Domain
import Foundation
import LocalAuthentication
import Testing

@testable import SystemServices

@Suite("NOT-07 / NOT-09 · Contenido del aviso")
struct ReminderContentTests {
    @Test("Sin montos, sin acciones y con la ruta a Inicio")
    func content() {
        let plan = ReminderPlan(
            identifier: "reminder.2026-10-10", fireDate: DateComponents(year: 2026, month: 10, day: 10, hour: 8),
            pendingNames: ["Renta", "Luz"])
        let content = UserNotificationReminderScheduler.content(for: plan, route: "today")
        #expect(content.body.contains("Renta"))
        #expect(!content.body.contains("$"))
        #expect(content.categoryIdentifier.isEmpty)
        #expect(content.userInfo["route"] as? String == "today")
        #expect(content.threadIdentifier == UserNotificationReminderScheduler.threadIdentifier)
    }
}

@Suite("SEG · Errores de LocalAuthentication")
struct LocalAuthenticationMappingTests {
    @Test(
        arguments: [
            (LAError.Code.userCancel, DeviceOwnerAuthResult.cancelled),
            (.appCancel, .cancelled),
            (.systemCancel, .cancelled),
            (.passcodeNotSet, .passcodeNotSet),
            (.authenticationFailed, .failed),
            (.biometryLockout, .failed),
        ])
    func mapping(code: LAError.Code, expected: DeviceOwnerAuthResult) {
        #expect(LocalAuthenticationService.result(for: code) == expected)
    }
}
