/// MND-01: la app trabaja con una sola moneda a la vez; nunca se convierten montos.
public enum Currency: String, CaseIterable, Codable, Sendable {
    case usd = "USD"
    case eur = "EUR"
}
