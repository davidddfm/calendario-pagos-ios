import Domain
import Foundation

/// MND-02: todos los montos con el símbolo de la moneda elegida.
/// `.narrow` garantiza `$` o `€` aunque la región del usuario tenga otra moneda local (R-04).
public enum MoneyFormatter {
    nonisolated public static func string(
        _ money: Money, currency: Currency, locale: Locale = .autoupdatingCurrent
    ) -> String {
        money.decimal.formatted(.currency(code: currency.rawValue).presentation(.narrow).locale(locale))
    }

    nonisolated public static func symbol(for currency: Currency) -> String {
        switch currency {
        case .usd: "$"
        case .eur: "€"
        }
    }
}
