/// Tipo de mutación, para decidir qué efectos secundarios ejecutar (§9.4).
public enum DataChange: Sendable {
    case payments, paymentStatus, salary, currency, reminderSettings
}

public protocol DataChangeObserving {
    func dataDidChange(_ change: DataChange)
}
