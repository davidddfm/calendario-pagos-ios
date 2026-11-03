import Foundation
import TestSupport
import Testing

@testable import Domain

@Suite("PAG-01 / PAG-02 · Validación de pagos", .tags(.payments))
struct PaymentValidatorTests {
    @Test func validDraft() {
        let draft = PaymentDraft(name: "  Renta  ", amount: Money(major: 500), dayOfMonth: 1)
        #expect(PaymentValidator.validate(draft).isEmpty)
        #expect(draft.trimmedName == "Renta")
    }

    @Test("Devuelve todos los errores a la vez")
    func allErrorsAtOnce() {
        let draft = PaymentDraft(name: " \n ", amount: nil, dayOfMonth: 0)
        #expect(PaymentValidator.validate(draft) == [.nameRequired, .amountRequired, .dayOutOfRange])
    }

    @Test("S-01 · Nombre hasta 60 caracteres", arguments: [(60, true), (61, false)])
    func nameLength(length: Int, isValid: Bool) {
        let draft = PaymentDraft(name: String(repeating: "á", count: length), amount: Money(major: 1), dayOfMonth: 1)
        #expect(PaymentValidator.validate(draft).isEmpty == isValid)
    }

    @Test(
        "S-01 · Monto mayor que cero y hasta 9,999,999.99",
        arguments: [
            (Int64(0), PaymentValidationError?.some(.amountRequired)),
            (1, nil),
            (999_999_999, nil),
            (1_000_000_000, .amountOutOfRange),
            (-100, .amountOutOfRange),
        ])
    func amountRange(minorUnits: Int64, expected: PaymentValidationError?) {
        let draft = PaymentDraft(name: "Pago", amount: Money(minorUnits: minorUnits), dayOfMonth: 1)
        #expect(PaymentValidator.validate(draft) == (expected.map { [$0] } ?? []))
    }

    @Test("Día del 1 al 31", arguments: [(0, false), (1, true), (31, true), (32, false), (-5, false)])
    func dayRange(day: Int, isValid: Bool) {
        let draft = PaymentDraft(name: "Pago", amount: Money(major: 1), dayOfMonth: day)
        #expect(PaymentValidator.validate(draft).isEmpty == isValid)
    }

    @Test("PAG-02 · Sin categoría queda en Gastos")
    func defaultCategory() {
        #expect(PaymentDraft(name: "x", amount: nil, dayOfMonth: 1).resolvedCategory == .expenses)
        #expect(PaymentDraft(name: "x", amount: nil, dayOfMonth: 1, category: .loans).resolvedCategory == .loans)
    }
}

@Suite("DAS-05 / CFG-01 · Validación del salario", .tags(.settings))
struct SalaryValidatorTests {
    @Test(
        arguments: [
            (Int64(999_999_900), true),  // 9,999,999 válido
            (999_999_901, false),  // 9,999,999.01 inválido
            (1, true),
            (0, false),
            (-100, false),
        ])
    func range(minorUnits: Int64, isValid: Bool) {
        let salary = Money(minorUnits: minorUnits)
        #expect(SalaryValidator.isValid(salary) == isValid)
        #expect((try? SalaryValidator.validated(salary)) == (isValid ? salary : nil))
    }

    @Test("Vacío significa sin salario")
    func emptyMeansNoSalary() throws {
        #expect(try SalaryValidator.validated(nil) == nil)
    }

    @Test func outOfRangeThrows() {
        #expect(throws: SalaryValidationError.outOfRange) { try SalaryValidator.validated(.zero) }
    }
}

@Suite("PAG-05 · Búsqueda sin mayúsculas ni acentos", .tags(.payments))
struct TextSearchTests {
    @Test(arguments: [
        ("Teléfono", "telefono", true),
        ("TELÉFONO móvil", "Movil", true),
        ("Préstamo coche", "  préstamo ", true),
        ("Internet", "", true),
        ("Internet", "luz", false),
        ("Ñandú", "nandu", true),
    ])
    func matches(name: String, query: String, expected: Bool) {
        #expect(TextSearch.matches(name, query: query) == expected)
    }
}

@Suite("§14.3 · Los errores tienen mensaje del catálogo")
struct ErrorMessageTests {
    @Test func allErrorsHaveMessages() {
        let errors: [any LocalizedError] = [
            PaymentValidationError.nameRequired, PaymentValidationError.nameTooLong,
            PaymentValidationError.amountRequired, PaymentValidationError.amountOutOfRange,
            PaymentValidationError.dayOutOfRange, DomainError.futurePeriod, DomainError.paymentNotFound,
            DomainError.paymentNotInPeriod, DomainError.invalidDate, SalaryValidationError.outOfRange,
        ]
        for error in errors {
            #expect(error.errorDescription?.isEmpty == false)
        }
        #expect(PaymentValidationError.nameRequired.errorDescription == "Escribe un nombre.")
    }
}
