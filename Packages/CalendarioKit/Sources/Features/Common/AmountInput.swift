import Domain
import Foundation

/// Lectura de montos escritos por el usuario, común a pagos, salario y herramientas.
enum AmountInput {
    /// Número en la configuración regional del usuario; `nil` si el campo está vacío o no es un número.
    static func decimal(_ text: String, locale: Locale) -> Decimal? {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        return try? Decimal.FormatStyle(locale: locale).parseStrategy.parse(text)
    }

    /// Texto editable de un monto guardado, sin separador de miles.
    static func text(_ money: Money, locale: Locale) -> String {
        money.decimal.formatted(.number.grouping(.never).locale(locale))
    }
}
