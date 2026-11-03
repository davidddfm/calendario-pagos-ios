import Domain
import Foundation

/// HER-08, MND-04, CAT-03 (§8.4): CSV RFC 4180 en UTF-8 con BOM, con fórmulas neutralizadas (OWASP).
public struct CSVPaymentExporter: PaymentsExporting {
    static let header = ["Nombre", "Monto", "Moneda", "Día", "Quincena", "Categoría"]

    private let timeZone: TimeZone
    private let directory: URL
    private let fileManager: FileManager

    /// - Parameter timeZone: la del reloj de la app; el nombre del archivo usa la fecha local.
    public init(
        timeZone: TimeZone,
        directory: URL = CSVPaymentExporter.defaultDirectory,
        fileManager: FileManager = .default
    ) {
        self.timeZone = timeZone
        self.directory = directory
        self.fileManager = fileManager
    }

    /// `ShareLink` no avisa al cerrarse: la carpeta se vacía antes de cada exportación y al arrancar.
    public static var defaultDirectory: URL {
        FileManager.default.temporaryDirectory.appending(path: "Exports", directoryHint: .isDirectory)
    }

    public func export(_ payments: [Payment], currency: Currency, date: Date) throws -> URL {
        try removeExports()
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appending(path: Self.fileName(date: date, timeZone: timeZone))
        try Data(Self.csv(payments, currency: currency).utf8).write(
            to: url, options: [.atomic, .completeFileProtection])
        return url
    }

    public func removeExports() throws {
        guard fileManager.fileExists(atPath: directory.path(percentEncoded: false)) else { return }
        try fileManager.removeItem(at: directory)
    }

    // MARK: - Formato

    /// HER-08: `pagos-AAAA-MM-DD.csv`. El estilo ISO 8601 usa GMT por defecto: la zona se pasa explícita.
    static func fileName(date: Date, timeZone: TimeZone) -> String {
        let day = date.formatted(Date.ISO8601FormatStyle(timeZone: timeZone).year().month().day())
        return "pagos-\(day).csv"
    }

    static func csv(_ payments: [Payment], currency: Currency) -> String {
        let rows = payments.map { payment in
            [
                text(payment.name),
                amount(payment.amount),
                currency.rawValue,
                String(payment.dayOfMonth),
                text(String(localized: payment.fortnight.localizedName)),
                text(String(localized: payment.category.localizedName)),
            ]
        }
        let lines = ([header.map(text)] + rows).map { $0.joined(separator: ",") }
        return "\u{FEFF}" + lines.joined(separator: "\r\n") + "\r\n"
    }

    /// Punto decimal y sin separador de miles: `1234.50`.
    static func amount(_ money: Money) -> String {
        let magnitude = money.minorUnits.magnitude
        let cents = magnitude % 100
        return "\(money.isNegative ? "-" : "")\(magnitude / 100).\(cents < 10 ? "0" : "")\(cents)"
    }

    /// Neutraliza fórmulas (CSV injection) y escapa según RFC 4180.
    static func text(_ value: String) -> String {
        let formulaPrefixes: Set<Character> = ["=", "+", "-", "@", "\t", "\r"]
        var value = value
        if let first = value.unicodeScalars.first, formulaPrefixes.contains(Character(first)) {
            value = "'" + value
        }
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0.isNewline }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}
