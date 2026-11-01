/// CFG-01 / DAS-05: salario neto mensual hasta 9,999,999 (sin centavos por encima de ese límite).
public enum SalaryValidator {
    public static let maxSalary = Money(minorUnits: 999_999_900)

    /// Campo vacío (`nil`) = sin salario. Devuelve el salario aceptado.
    public static func validated(_ salary: Money?) throws(SalaryValidationError) -> Money? {
        guard let salary else { return nil }
        guard salary > .zero, salary <= maxSalary else { throw .outOfRange }
        return salary
    }

    public static func isValid(_ salary: Money) -> Bool {
        salary > .zero && salary <= maxSalary
    }
}
