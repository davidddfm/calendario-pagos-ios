import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("PAG-07 · Día efectivo en meses cortos", .tags(.payments))
struct EffectiveDayTests {
    @Test(arguments: [
        (2026, 2, 31, 28),
        (2028, 2, 31, 29),  // bisiesto
        (2100, 2, 31, 28),  // múltiplo de 100, no bisiesto
        (2000, 2, 30, 29),  // múltiplo de 400, bisiesto
        (2026, 4, 31, 30),
        (2026, 1, 31, 31),
        (2026, 2, 15, 15),
    ])
    func effectiveDay(year: Int, month: Int, scheduledDay: Int, expected: Int) throws {
        let period = try #require(YearMonth(year: year, month: month))
        #expect(period.effectiveDay(for: scheduledDay) == expected)
    }

    @Test("Claves corruptas no construyen un mes", arguments: [0, 202613, 202600, 99_999_999, -202601, 196912])
    func invalidKey(key: Int) {
        #expect(YearMonth(key: key) == nil)
    }

    @Test func keyRoundTrip() throws {
        let period = try YearMonth.make(2026, 10)
        #expect(period.key == 202610)
        #expect(YearMonth(key: 202610) == period)
    }

    @Test(
        "CAL-02 · Navegar meses sin límite",
        arguments: [
            (2026, 12, 1, 2027, 1),
            (2026, 1, -1, 2025, 12),
            (2026, 10, -22, 2024, 12),
            (2026, 10, 27, 2029, 1),
            (2026, 10, 0, 2026, 10),
        ])
    func addingMonths(year: Int, month: Int, delta: Int, expectedYear: Int, expectedMonth: Int) throws {
        let result = try YearMonth.make(year, month).adding(months: delta)
        #expect(result.year == expectedYear)
        #expect(result.month == expectedMonth)
    }

    @Test func ordering() throws {
        #expect(try YearMonth.make(2025, 12) < YearMonth.make(2026, 1))
        #expect(try YearMonth.make(2026, 2) > YearMonth.make(2026, 1))
    }

    @Test func containingDate() throws {
        let calendar = Calendar.testGregorian
        let date = try calendar.date(year: 2026, month: 3, day: 31, hour: 23, minute: 59)
        #expect(YearMonth(containing: date, calendar: calendar) == (try YearMonth.make(2026, 3)))
    }

    @Test func dateUsesEffectiveDay() throws {
        let calendar = Calendar.testGregorian
        let date = try #require(try YearMonth.make(2026, 2).date(day: 31, calendar: calendar))
        #expect(calendar.component(.day, from: date) == 28)
    }
}

@Suite("PAG-03 · Quincena derivada del día", .tags(.payments))
struct FortnightTests {
    @Test(arguments: [(1, Fortnight.first), (15, .first), (16, .second), (31, .second)])
    func fortnight(day: Int, expected: Fortnight) {
        #expect(Fortnight(dayOfMonth: day) == expected)
    }
}

@Suite("CAT · Categorías fijas", .tags(.payments))
struct PaymentCategoryTests {
    @Test("CAT-01 · Lista fija de 7 categorías")
    func fixedList() {
        #expect(PaymentCategory.allCases.count == 7)
    }

    @Test("PAG-02 · La categoría por defecto es Gastos")
    func defaultCategory() {
        #expect(PaymentCategory.default == .expenses)
    }

    @Test("Valores guardados desconocidos caen en Gastos", arguments: ["", "comida", "GASTOS", "servicios "])
    func unknownStoredValue(value: String) {
        #expect(PaymentCategory(storedValue: value) == .expenses)
    }

    @Test("Los valores crudos persistidos no cambian")
    func stableRawValues() {
        #expect(
            PaymentCategory.allCases.map(\.rawValue) == [
                "gastos", "ahorros", "inversiones", "bienestar", "prestamos", "transportes", "servicios",
            ])
    }

    @Test(
        "CAT-03 · Nombres en español",
        arguments: [
            (PaymentCategory.expenses, "Gastos"),
            (.savings, "Ahorros"),
            (.investments, "Inversiones"),
            (.wellbeing, "Bienestar"),
            (.loans, "Préstamos"),
            (.transport, "Transportes"),
            (.utilities, "Servicios"),
        ])
    func localizedName(category: PaymentCategory, expected: String) {
        var resource = category.localizedName
        resource.locale = Locale(identifier: "es_MX")
        #expect(String(localized: resource) == expected)
    }

    @Test(
        "S-03 · Clasificación 50/30/20",
        arguments: [
            (PaymentCategory.utilities, BudgetBucket.needs),
            (.transport, .needs),
            (.loans, .needs),
            (.expenses, .needs),
            (.wellbeing, .wants),
            (.savings, .savings),
            (.investments, .savings),
        ])
    func budgetBucket(category: PaymentCategory, expected: BudgetBucket) {
        #expect(category.budgetBucket == expected)
    }
}
