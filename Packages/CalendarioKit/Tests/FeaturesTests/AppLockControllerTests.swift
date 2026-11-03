import Domain
import Foundation
import TestSupport
import Testing

@testable import Features

@Suite("SEG-01 a SEG-04 · Bloqueo de la app")
struct AppLockControllerTests {
    let settings = InMemorySettingsRepository(
        AppSettings(
            currency: .usd, appLock: AppLockSettings(isEnabled: true, gracePeriod: .oneMinute),
            hasCompletedOnboarding: true))
    let clock: MutableClock

    init() throws {
        clock = MutableClock(now: try Calendar.testGregorian.date(year: 2026, month: 10, day: 10))
    }

    private func makeController(_ authenticator: StubAuthenticator) -> AppLockController {
        AppLockController(
            getSettings: GetSettingsUseCase(settings: settings),
            updateAppLock: UpdateAppLockSettingsUseCase(settings: settings),
            authenticator: authenticator,
            clock: clock)
    }

    @Test("SEG-03 · Arranca bloqueada y se desbloquea al autenticarse")
    func coldStart() async {
        let controller = makeController(StubAuthenticator())
        #expect(controller.isLocked)
        await controller.unlock()
        #expect(!controller.isLocked)
    }

    @Test("Cancelar o fallar no desbloquea", arguments: [DeviceOwnerAuthResult.cancelled, .failed])
    func failedUnlock(result: DeviceOwnerAuthResult) async {
        let controller = makeController(StubAuthenticator(result: result))
        await controller.unlock()
        #expect(controller.isLocked)
    }

    @Test(
        "SEG-02 · Vuelve a bloquear tras el tiempo elegido",
        arguments: [(30.0, false), (59.0, false), (60.0, true), (600.0, true)])
    func gracePeriod(seconds: TimeInterval, locks: Bool) async {
        let controller = makeController(StubAuthenticator())
        await controller.unlock()
        controller.didEnterBackground()
        clock.advance(by: seconds)
        controller.didBecomeActive()
        #expect(controller.isLocked == locks)
    }

    @Test("SEG-02 · Si el reloj retrocede, bloquea")
    func clockMovedBack() async {
        let controller = makeController(StubAuthenticator())
        await controller.unlock()
        controller.didEnterBackground()
        clock.advance(by: -3_600)
        controller.didBecomeActive()
        #expect(controller.isLocked)
    }

    @Test("El diálogo de Face ID (sin pasar a segundo plano) no vuelve a bloquear")
    func activeWithoutBackground() async {
        let controller = makeController(StubAuthenticator())
        await controller.unlock()
        clock.advance(by: 600)
        controller.didBecomeActive()
        #expect(!controller.isLocked)
    }

    @Test("SEG-04 · Sin código en el iPhone se desactiva solo y avisa")
    func passcodeRemoved() {
        let authenticator = StubAuthenticator(availability: .passcodeNotSet)
        let controller = makeController(authenticator)
        controller.didBecomeActive()
        #expect(!controller.isLocked)
        #expect(controller.showsPasscodeRemovedAlert)
        #expect(!settings.stored.appLock.isEnabled)
        #expect(settings.stored.appLock.gracePeriod == .oneMinute)
    }

    @Test("SEG-01 · Con el bloqueo apagado nunca se bloquea")
    func disabled() throws {
        try settings.save(AppSettings(currency: .usd, hasCompletedOnboarding: true))
        let controller = makeController(StubAuthenticator())
        #expect(!controller.isLocked)
        controller.didEnterBackground()
        clock.advance(by: 3_600)
        controller.didBecomeActive()
        #expect(!controller.isLocked)
    }
}
