import Foundation

/// Cantidad monetaria en unidades menores (centavos). La moneda es global (MND-02) y no forma parte del valor.
public struct Money: Hashable, Comparable, Sendable {
    public let minorUnits: Int64

    public static let zero = Money(minorUnits: 0)

    /// Límite absoluto aceptado en cualquier entrada (salario o pago): 9,999,999.99.
    /// Con este límite, ninguna suma, × 12 o porcentaje del dominio puede desbordar `Int64`.
    public static let maxInputMinorUnits: Int64 = 999_999_999

    public init(minorUnits: Int64) { self.minorUnits = minorUnits }

    /// Convierte la entrada del usuario redondeando a 2 decimales.
    /// Devuelve `nil` si el valor es negativo, no es finito o supera `maxInputMinorUnits`;
    /// así nunca se convierte un `Decimal` fuera de rango a `Int64`.
    public init?(validatingInput decimal: Decimal) {
        guard decimal.isFinite, decimal >= 0 else { return nil }
        var scaled = decimal * 100
        var rounded = Decimal()
        NSDecimalRound(&rounded, &scaled, 0, .plain)
        guard rounded <= Decimal(Self.maxInputMinorUnits) else { return nil }
        self.minorUnits = NSDecimalNumber(decimal: rounded).int64Value
    }

    public var decimal: Decimal { Decimal(minorUnits) / 100 }
    public var isNegative: Bool { minorUnits < 0 }

    public static func + (lhs: Money, rhs: Money) -> Money { Money(minorUnits: lhs.minorUnits + rhs.minorUnits) }
    public static func - (lhs: Money, rhs: Money) -> Money { Money(minorUnits: lhs.minorUnits - rhs.minorUnits) }
    public static func < (lhs: Money, rhs: Money) -> Bool { lhs.minorUnits < rhs.minorUnits }

    public func multiplied(by factor: Int64) -> Money { Money(minorUnits: minorUnits * factor) }

    /// Porcentaje entero (p. ej. 50 → 50 %). Trunca hacia cero.
    public func percent(_ value: Int64) -> Money { Money(minorUnits: minorUnits * value / 100) }

    /// Proporción respecto de otro monto; 0 si el divisor es 0.
    public func ratio(to other: Money) -> Double {
        other.minorUnits == 0 ? 0 : Double(minorUnits) / Double(other.minorUnits)
    }
}

// MARK: - Codable

/// Se codifica como el entero de unidades menores (ajustes, §7.4). La validación de rango la hace quien lee.
extension Money: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.minorUnits = try container.decode(Int64.self)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(minorUnits)
    }
}

extension Sequence where Element == Money {
    public func sum() -> Money { reduce(.zero, +) }
}
