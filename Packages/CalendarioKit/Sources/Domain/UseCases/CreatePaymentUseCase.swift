import Foundation

/// PAG-01, PAG-02, PAG-03.
public struct CreatePaymentUseCase {
    private let payments: any PaymentRepository
    private let clock: any DateProviding
    private let observer: any DataChangeObserving

    public init(payments: any PaymentRepository, clock: any DateProviding, observer: any DataChangeObserving) {
        self.payments = payments
        self.clock = clock
        self.observer = observer
    }

    @discardableResult
    public func execute(_ draft: PaymentDraft) throws -> Payment {
        let errors = PaymentValidator.validate(draft)
        guard errors.isEmpty, let amount = draft.amount else { throw DomainError.invalidPayment(errors) }

        let now = clock.now
        let payment = Payment(
            id: UUID(),
            name: draft.trimmedName,
            amount: amount,
            dayOfMonth: draft.dayOfMonth,
            category: draft.resolvedCategory,
            createdAt: now,
            updatedAt: now
        )
        try payments.insert(payment)
        observer.dataDidChange(.payments)
        return payment
    }
}
