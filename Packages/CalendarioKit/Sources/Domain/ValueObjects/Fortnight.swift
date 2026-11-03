import Foundation

/// PAG-03: la quincena se deriva del día; el usuario no la elige.
public enum Fortnight: Int, CaseIterable, Sendable, Codable {
    /// Días 1–15.
    case first = 1
    /// Días 16–31.
    case second = 2

    public init(dayOfMonth: Int) { self = dayOfMonth <= 15 ? .first : .second }
}

extension Fortnight {
    /// Nombre corto para el CSV (§8.4).
    public var localizedName: LocalizedStringResource {
        switch self {
        case .first: LocalizedStringResource("Primera", bundle: .domain)
        case .second: LocalizedStringResource("Segunda", bundle: .domain)
        }
    }
}
