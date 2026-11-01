import Foundation

/// Mes del calendario gregoriano (la app siempre usa `Calendar(identifier: .gregorian)`, §8.5).
/// Clave de persistencia AAAAMM (p. ej. 202610). Solo se construye con valores válidos.
///
/// No conforma a `Codable` a propósito: la decodificación sintetizada se saltaría la validación.
public struct YearMonth: Hashable, Comparable, Sendable {
    public let year: Int
    /// 1...12
    public let month: Int

    /// `nil` si el mes o el año están fuera de rango (datos corruptos o entrada inválida).
    public init?(year: Int, month: Int) {
        guard (1...12).contains(month), (1970...9999).contains(year) else { return nil }
        self.year = year
        self.month = month
    }

    /// `Calendar.component(_:from:)` no devuelve opcionales: no hay desempaquetado forzado.
    public init(containing date: Date, calendar: Calendar) {
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
    }

    public init?(key: Int) { self.init(year: key / 100, month: key % 100) }

    public var key: Int { year * 100 + month }

    public static func < (lhs: YearMonth, rhs: YearMonth) -> Bool { lhs.key < rhs.key }

    /// Aritmética entera; los años de la app son positivos, así que la división trunca correctamente.
    public func adding(months: Int) -> YearMonth {
        let index = year * 12 + (month - 1) + months
        return YearMonth(uncheckedYear: index / 12, month: index % 12 + 1)
    }

    /// Cálculo gregoriano puro: no depende de API opcionales de `Calendar`.
    public var numberOfDays: Int {
        switch month {
        case 2: Self.isLeap(year) ? 29 : 28
        case 4, 6, 9, 11: 30
        default: 31
        }
    }

    /// PAG-07: un pago programado en un día que el mes no tiene se muestra el último día del mes.
    public func effectiveDay(for scheduledDay: Int) -> Int {
        min(max(scheduledDay, 1), numberOfDays)
    }

    /// Fecha del día efectivo. Opcional porque `Calendar.date(from:)` lo es; quien llama decide qué hacer con `nil`.
    public func date(day: Int, calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: effectiveDay(for: day)))
    }

    private init(uncheckedYear: Int, month: Int) {
        self.year = uncheckedYear
        self.month = month
    }

    private static func isLeap(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || year % 400 == 0
    }
}
