/// SEG-02: tiempo en segundo plano antes de volver a pedir autenticación, en segundos.
public enum LockGracePeriod: Int, CaseIterable, Sendable, Codable {
    case immediately = 0
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
}
