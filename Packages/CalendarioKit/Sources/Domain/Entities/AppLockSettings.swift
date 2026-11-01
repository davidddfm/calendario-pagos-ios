/// Bloqueo de la app (SEG-01, SEG-02).
public struct AppLockSettings: Equatable, Sendable {
    /// SEG-01: apagado por defecto.
    public var isEnabled: Bool
    /// SEG-02: 1 minuto por defecto.
    public var gracePeriod: LockGracePeriod

    public init(isEnabled: Bool = false, gracePeriod: LockGracePeriod = .oneMinute) {
        self.isEnabled = isEnabled
        self.gracePeriod = gracePeriod
    }
}

// MARK: - Codable

extension AppLockSettings: Codable {
    private enum CodingKeys: String, CodingKey { case isEnabled, gracePeriod }

    public init(from decoder: any Decoder) throws {
        let defaults = AppLockSettings()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = container.decodeOrDefault(Bool.self, forKey: .isEnabled, default: defaults.isEnabled)
        self.gracePeriod = container.decodeOrDefault(
            LockGracePeriod.self, forKey: .gracePeriod, default: defaults.gracePeriod)
    }
}
