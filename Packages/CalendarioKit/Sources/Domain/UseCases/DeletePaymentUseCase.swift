import Foundation

/// PAG-04 (la confirmación es de la UI) y ADR-07: borrado lógico para conservar el historial.
public struct DeletePaymentUseCase {
    private let payments: any PaymentRepository
    private let clock: any DateProviding
    private let observer: any DataChangeObserving

    public init(payments: any PaymentRepository, clock: any DateProviding, observer: any DataChangeObserving) {
        self.payments = payments
        self.clock = clock
        self.observer = observer
    }

    public func execute(id: UUID) throws {
        guard let payment = try payments.payment(id: id), payment.deletedAt == nil else {
            throw DomainError.paymentNotFound
        }
        try payments.markDeleted(id: id, at: clock.now)
        observer.dataDidChange(.payments)
    }
}
