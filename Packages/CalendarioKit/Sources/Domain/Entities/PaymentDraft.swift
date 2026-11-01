/// Datos del formulario de pago antes de validarlos (PAG-01, PAG-02).
public struct PaymentDraft: Equatable, Sendable {
    public var name: String
    /// `nil` mientras el campo de monto está vacío o no es un número válido.
    public var amount: Money?
    public var dayOfMonth: Int
    /// `nil` = el usuario no eligió categoría (PAG-02).
    public var category: PaymentCategory?

    public init(name: String, amount: Money?, dayOfMonth: Int, category: PaymentCategory? = nil) {
        self.name = name
        self.amount = amount
        self.dayOfMonth = dayOfMonth
        self.category = category
    }

    public var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// PAG-02 / CAT-02
    public var resolvedCategory: PaymentCategory { category ?? .default }
}
