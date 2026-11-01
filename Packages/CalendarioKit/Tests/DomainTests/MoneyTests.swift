import Foundation
import Testing

@testable import Domain

@Suite("Money · entrada validada y aritmética exacta", .tags(.payments))
struct MoneyTests {
    @Test(
        "Redondea a 2 decimales",
        arguments: [
            ("10.005", Int64(1001)),
            ("10.004", 1000),
            ("0", 0),
            ("9999999.99", 999_999_999),
        ])
    func roundsInput(input: String, expected: Int64) throws {
        let decimal = try #require(Decimal(string: input, locale: Locale(identifier: "en_US_POSIX")))
        #expect(Money(validatingInput: decimal)?.minorUnits == expected)
    }

    @Test(
        "Entradas inválidas no construyen un monto",
        arguments: [
            Decimal.nan,
            Decimal(-1),
            Decimal(string: "10000000"),
            Decimal(string: "100000000000000000000"),
            Decimal(string: "9999999.996"),
        ])
    func rejectsInvalidInput(input: Decimal?) throws {
        let decimal = try #require(input)
        #expect(Money(validatingInput: decimal) == nil)
    }

    @Test func arithmetic() {
        let a = Money(minorUnits: 1_050)
        let b = Money(minorUnits: 250)
        #expect((a + b).minorUnits == 1_300)
        #expect((b - a).minorUnits == -800)
        #expect((b - a).isNegative)
        #expect(a.multiplied(by: 12).minorUnits == 12_600)
        #expect([a, b, b].sum().minorUnits == 1_550)
        #expect([Money]().sum() == .zero)
    }

    @Test("percent trunca hacia cero")
    func percentTruncates() {
        #expect(Money(minorUnits: 100_001).percent(50).minorUnits == 50_000)
        #expect(Money(minorUnits: 100_001).percent(30).minorUnits == 30_000)
    }

    @Test func ratioWithZeroDivisorIsZero() {
        #expect(Money(minorUnits: 100).ratio(to: .zero) == 0)
        #expect(Money(minorUnits: 50).ratio(to: Money(minorUnits: 200)) == 0.25)
    }

    @Test func decimalValue() {
        #expect(Money(minorUnits: 12_345).decimal == Decimal(string: "123.45"))
    }

    @Test func codableRoundTrip() throws {
        let data = try JSONEncoder().encode(Money(minorUnits: 4_200))
        #expect(String(decoding: data, as: UTF8.self) == "4200")
        #expect(try JSONDecoder().decode(Money.self, from: data) == Money(minorUnits: 4_200))
    }
}
