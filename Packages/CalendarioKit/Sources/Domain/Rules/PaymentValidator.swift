/// PAG-01 y supuesto S-01 (§5.4).
public enum PaymentValidator {
    public static let maxNameLength = 60
    public static let validDays = 1...31

    /// Devuelve todos los errores a la vez; vacío = válido.
    public static func validate(_ draft: PaymentDraft) -> [PaymentValidationError] {
        var errors: [PaymentValidationError] = []

        let name = draft.trimmedName
        if name.isEmpty {
            errors.append(.nameRequired)
        } else if name.count > maxNameLength {
            errors.append(.nameTooLong)
        }

        switch draft.amount {
        case nil:
            errors.append(.amountRequired)
        case let amount?:
            if amount.minorUnits == 0 {
                errors.append(.amountRequired)
            } else if amount.isNegative || amount.minorUnits > Money.maxInputMinorUnits {
                errors.append(.amountOutOfRange)
            }
        }

        if !validDays.contains(draft.dayOfMonth) {
            errors.append(.dayOutOfRange)
        }
        return errors
    }
}
