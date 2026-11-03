/// SEG-01 / SEG-04.
public enum DeviceOwnerAuthAvailability: Sendable {
    case available, passcodeNotSet, unavailable
}

public enum DeviceOwnerAuthResult: Sendable {
    case success, cancelled, failed, passcodeNotSet
}

/// Para nombrar el método en Ajustes ("Face ID", "Touch ID" o "código").
public enum DeviceBiometry: Sendable {
    case faceID, touchID, none
}

/// Face ID, Touch ID o el código del iPhone (§8.2).
public protocol DeviceOwnerAuthenticating: Sendable {
    func availability() -> DeviceOwnerAuthAvailability
    func biometry() -> DeviceBiometry
    func authenticate(reason: String) async -> DeviceOwnerAuthResult
}
