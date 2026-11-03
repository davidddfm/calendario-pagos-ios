/// Ajustes de avisos (NOT-01, NOT-02, NOT-05).
public struct ReminderSettings: Equatable, Sendable {
    /// NOT-01: activados por defecto.
    public var isEnabled: Bool
    /// NOT-01: 8:00 por defecto.
    public var hour: Int
    public var minute: Int
    /// S-08 / NOT-06: la explicación previa al permiso se muestra una sola vez.
    public var hasOfferedPermission: Bool

    public init(isEnabled: Bool = true, hour: Int = 8, minute: Int = 0, hasOfferedPermission: Bool = false) {
        self.isEnabled = isEnabled
        self.hour = hour
        self.minute = minute
        self.hasOfferedPermission = hasOfferedPermission
    }
}

// MARK: - Codable

/// Cada campo ilegible o ausente toma su valor por defecto sin invalidar el resto (§7.4).
extension ReminderSettings: Codable {
    private enum CodingKeys: String, CodingKey { case isEnabled, hour, minute, hasOfferedPermission }

    public init(from decoder: any Decoder) throws {
        let defaults = ReminderSettings()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.isEnabled = container.decodeOrDefault(Bool.self, forKey: .isEnabled, default: defaults.isEnabled)
        self.hour = container.decodeOrDefault(Int.self, forKey: .hour, default: defaults.hour)
        self.minute = container.decodeOrDefault(Int.self, forKey: .minute, default: defaults.minute)
        self.hasOfferedPermission = container.decodeOrDefault(
            Bool.self, forKey: .hasOfferedPermission, default: defaults.hasOfferedPermission)
    }
}
