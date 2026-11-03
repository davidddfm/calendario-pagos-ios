import Foundation

/// HER-08: genera el archivo de exportación (§8.4).
public protocol PaymentsExporting {
    /// Escribe el CSV y devuelve la URL temporal del archivo.
    func export(_ payments: [Payment], currency: Currency, date: Date) throws -> URL
}
