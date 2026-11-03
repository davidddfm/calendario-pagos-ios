import Foundation

/// Texto del aviso diario (NOT-07): cuántos pagos hay y sus nombres, nunca montos.
public enum ReminderText {
    /// Nombres que se listan antes de resumir con "y N más".
    public static let maxNames = 4

    public static func title(locale: Locale = .autoupdatingCurrent) -> String {
        String(localized: "Pagos de hoy", bundle: .module, locale: locale)
    }

    public static func body(names: [String], locale: Locale = .autoupdatingCurrent) -> String {
        let list: String
        if names.count > maxNames {
            let shown = names.prefix(maxNames).joined(separator: ", ")
            list = String(
                localized: "\(shown) y \(names.count - maxNames) más", bundle: .module, locale: locale,
                comment: "Aviso diario con más de 4 pagos (NOT-07)")
        } else {
            list = names.formatted(.list(type: .and).locale(locale))
        }
        return names.count == 1
            ? String(localized: "Tienes 1 pago hoy: \(list).", bundle: .module, locale: locale)
            : String(localized: "Tienes \(names.count) pagos hoy: \(list).", bundle: .module, locale: locale)
    }
}
