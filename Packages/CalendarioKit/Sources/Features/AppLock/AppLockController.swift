import Domain
import Foundation
import Observation

/// Bloqueo de la app (SEG-01 a SEG-04, §8.2). Ante la duda, bloquea.
@Observable
public final class AppLockController {
    public private(set) var isLocked: Bool
    public private(set) var isAuthenticating = false
    /// SEG-04: el iPhone dejó de tener código y el bloqueo se desactivó solo.
    public private(set) var showsPasscodeRemovedAlert = false

    private var backgroundedAt: Date?
    private let getSettings: GetSettingsUseCase
    private let updateAppLock: UpdateAppLockSettingsUseCase
    private let authenticator: any DeviceOwnerAuthenticating
    private let clock: any DateProviding

    public init(
        getSettings: GetSettingsUseCase,
        updateAppLock: UpdateAppLockSettingsUseCase,
        authenticator: any DeviceOwnerAuthenticating,
        clock: any DateProviding
    ) {
        self.getSettings = getSettings
        self.updateAppLock = updateAppLock
        self.authenticator = authenticator
        self.clock = clock
        // SEG-03: en un arranque en frío se bloquea antes del primer cuadro.
        isLocked = getSettings.execute().appLock.isEnabled
    }

    public func didEnterBackground() {
        backgroundedAt = clock.now
    }

    /// `.inactive` no llega aquí: el diálogo de Face ID lo provoca y no debe volver a bloquear.
    public func didBecomeActive() {
        defer { backgroundedAt = nil }
        let appLock = getSettings.execute().appLock
        guard appLock.isEnabled else {
            isLocked = false
            return
        }
        if authenticator.availability() == .passcodeNotSet {
            disableAfterPasscodeRemoval(appLock)
            return
        }
        guard let backgroundedAt else { return }
        let now = clock.now
        // SEG-02. Si el reloj del sistema retrocedió, también se bloquea.
        if now < backgroundedAt || now.timeIntervalSince(backgroundedAt) >= TimeInterval(appLock.gracePeriod.rawValue) {
            isLocked = true
        }
    }

    /// Con `.cancelled` o `.failed` la app sigue bloqueada; nunca se desbloquea por omisión.
    public func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }
        let reason = String(localized: "Desbloquea la app para ver tus pagos.", bundle: .module)
        switch await authenticator.authenticate(reason: reason) {
        case .success: isLocked = false
        case .passcodeNotSet: disableAfterPasscodeRemoval(getSettings.execute().appLock)
        case .cancelled, .failed: break
        }
    }

    public func dismissPasscodeRemovedAlert() { showsPasscodeRemovedAlert = false }

    /// SEG-04
    private func disableAfterPasscodeRemoval(_ appLock: AppLockSettings) {
        var disabled = appLock
        disabled.isEnabled = false
        // Si no se puede guardar, se volverá a intentar en la siguiente activación.
        try? updateAppLock.execute(disabled)
        isLocked = false
        showsPasscodeRemovedAlert = true
    }
}
