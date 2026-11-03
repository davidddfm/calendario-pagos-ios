import Domain
import LocalAuthentication

/// SEG-01, SEG-04 (§8.2): Face ID, Touch ID o el código del iPhone.
public struct LocalAuthenticationService: DeviceOwnerAuthenticating {
    public init() {}

    public func availability() -> DeviceOwnerAuthAvailability {
        var error: NSError?
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) { return .available }
        return error.map { LAError.Code(rawValue: $0.code) == .passcodeNotSet } == true ? .passcodeNotSet : .unavailable
    }

    public func biometry() -> DeviceBiometry {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return switch context.biometryType {
        case .faceID: .faceID
        case .touchID: .touchID
        default: .none
        }
    }

    /// Un `LAContext` nuevo por intento: uno reutilizado puede devolver una autenticación ya evaluada.
    /// Los errores se traducen para que la UI distinga cancelar de fallar; nunca se desbloquea por omisión.
    public func authenticate(reason: String) async -> DeviceOwnerAuthResult {
        do {
            return try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
                ? .success : .failed
        } catch let error as LAError {
            return Self.result(for: error.code)
        } catch {
            return .failed
        }
    }

    static func result(for code: LAError.Code) -> DeviceOwnerAuthResult {
        switch code {
        case .userCancel, .appCancel, .systemCancel: .cancelled
        case .passcodeNotSet: .passcodeNotSet
        default: .failed
        }
    }
}
