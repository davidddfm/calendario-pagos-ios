import Foundation

/// Carga un pago vigente para editarlo (PAG-01, CAL-06).
public struct GetPaymentUseCase {
    private let payments: any PaymentRepository

    public init(payments: any PaymentRepository) {
        self.payments = payments
    }

    public func execute(id: UUID) throws -> Payment {
        guard let payment = try payments.payment(id: id), payment.deletedAt == nil else {
            throw DomainError.paymentNotFound
        }
        return payment
    }
}
