import Foundation

/// CFG-01 / DAS-05.
public enum SalaryValidationError: Error, Equatable, Sendable {
    case outOfRange
}

extension SalaryValidationError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .outOfRange: String(localized: "El salario debe ser mayor que cero y hasta 9,999,999.", bundle: .module)
        }
    }
}
