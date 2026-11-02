import Foundation

/// PAG-01. No toca los registros: el historial conserva la instantánea (MAR-04).
public struct UpdatePaymentUseCase {
    private let payments: any PaymentRepository
    private let clock: any DateProviding
    private let observer: any DataChangeObserving

    public init(payments: any PaymentRepository, clock: any DateProviding, observer: any DataChangeObserving) {
        self.payments = payments
        self.clock = clock
        self.observer = observer
    }

    @discardableResult
    public func execute(id: UUID, draft: PaymentDraft) throws -> Payment {
        let errors = PaymentValidator.validate(draft)
        guard errors.isEmpty, let amount = draft.amount else { throw DomainError.invalidPayment(errors) }
        guard var payment = try payments.payment(id: id), payment.deletedAt == nil else {
            throw DomainError.paymentNotFound
        }

        payment.name = draft.trimmedName
        payment.amount = amount
        payment.dayOfMonth = draft.dayOfMonth
        payment.category = draft.resolvedCategory
        payment.updatedAt = clock.now
        try payments.update(payment)
        observer.dataDidChange(.payments)
        return payment
    }
}
