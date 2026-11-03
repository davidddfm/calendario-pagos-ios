import Domain
import Foundation
import TestSupport
import Testing

@testable import SystemServices

@Suite("HER-08 / MND-04 / CAT-03 · Exportación CSV")
struct CSVPaymentExporterTests {
    let calendar = Calendar.testGregorian

    private func payment(_ name: String, minorUnits: Int64, day: Int, category: PaymentCategory) throws -> Payment {
        Payment.fixture(
            name: name, amount: Money(minorUnits: minorUnits), day: day, category: category,
            createdAt: try calendar.date(year: 2026, month: 1, day: 1))
    }

    @Test("Encabezado, BOM, fin de línea CRLF, moneda, quincena y categoría")
    func format() throws {
        let csv = CSVPaymentExporter.csv(
            [
                try payment("Renta", minorUnits: 123_450, day: 1, category: .utilities),
                try payment("Gimnasio", minorUnits: 3_005, day: 20, category: .wellbeing),
            ],
            currency: .eur)

        #expect(csv.hasPrefix("\u{FEFF}"))
        let lines = csv.dropFirst().components(separatedBy: "\r\n")
        #expect(
            lines == [
                "Nombre,Monto,Moneda,Día,Quincena,Categoría",
                "Renta,1234.50,EUR,1,Primera,Servicios",
                "Gimnasio,30.05,EUR,20,Segunda,Bienestar",
                "",
            ])
    }

    @Test(
        "RFC 4180 y neutralización de fórmulas (OWASP)",
        arguments: [
            ("Luz, agua", "\"Luz, agua\""),
            ("Plan \"pro\"", "\"Plan \"\"pro\"\"\""),
            ("Línea\nnueva", "\"Línea\nnueva\""),
            ("=HYPERLINK(\"x\")", "\"'=HYPERLINK(\"\"x\"\")\""),
            ("+1", "'+1"),
            ("-1", "'-1"),
            ("@SUM(A1)", "'@SUM(A1)"),
            ("\tTab", "'\tTab"),
            ("\r\nCR", "\"'\r\nCR\""),
            ("Netflix", "Netflix"),
        ])
    func escaping(input: String, expected: String) {
        #expect(CSVPaymentExporter.text(input) == expected)
    }

    @Test(
        "Monto con punto decimal y sin separador de miles",
        arguments: [(0, "0.00"), (5, "0.05"), (1_000, "10.00"), (999_999_999, "9999999.99"), (-150, "-1.50")])
    func amount(minorUnits: Int64, expected: String) {
        #expect(CSVPaymentExporter.amount(Money(minorUnits: minorUnits)) == expected)
    }

    @Test("HER-08 · El nombre usa la fecha local, no la de GMT")
    func fileNameUsesLocalDate() throws {
        // 2 de noviembre a las 23:30 en Ciudad de México = 3 de noviembre en GMT.
        let mexico = try #require(TimeZone(identifier: "America/Mexico_City"))
        var local = calendar
        local.timeZone = mexico
        let lateNight = try local.date(year: 2026, month: 11, day: 2, hour: 23, minute: 30)
        #expect(CSVPaymentExporter.fileName(date: lateNight, timeZone: mexico) == "pagos-2026-11-02.csv")
    }

    @Test("Escribe el archivo y vacía las exportaciones anteriores")
    func writesAndCleans() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "ExportsTests-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: directory) }
        let exporter = CSVPaymentExporter(timeZone: calendar.timeZone, directory: directory)

        let first = try exporter.export(
            [try payment("Renta", minorUnits: 50_000, day: 1, category: .utilities)], currency: .usd,
            date: try calendar.date(year: 2026, month: 10, day: 30))
        let second = try exporter.export(
            [], currency: .usd, date: try calendar.date(year: 2026, month: 10, day: 31))

        #expect(second.lastPathComponent == "pagos-2026-10-31.csv")
        #expect(!FileManager.default.fileExists(atPath: first.path(percentEncoded: false)))
        let data = try Data(contentsOf: second)
        #expect(data.starts(with: [0xEF, 0xBB, 0xBF]))  // BOM UTF-8

        try exporter.removeExports()
        #expect(!FileManager.default.fileExists(atPath: directory.path(percentEncoded: false)))
    }
}
