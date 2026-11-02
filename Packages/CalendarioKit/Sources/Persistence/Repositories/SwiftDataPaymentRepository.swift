import Domain
import Foundation
import SwiftData

public final class SwiftDataPaymentRepository: PaymentRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func payments(includingDeleted: Bool) throws -> [Payment] {
        let descriptor =
            includingDeleted
            ? FetchDescriptor<PaymentEntity>()
            : FetchDescriptor<PaymentEntity>(predicate: #Predicate { $0.deletedAt == nil })
        return try context.fetchOrThrow(descriptor).compactMap(PaymentMapper.toDomain)
    }

    public func payment(id: UUID) throws -> Payment? {
        try entity(id: id).flatMap(PaymentMapper.toDomain)
    }

    public func insert(_ payment: Payment) throws {
        context.insert(PaymentMapper.makeEntity(from: payment))
        try context.saveOrThrow()
    }

    public func update(_ payment: Payment) throws {
        guard let entity = try entity(id: payment.id) else { throw DomainError.paymentNotFound }
        PaymentMapper.apply(payment, to: entity)
        try context.saveOrThrow()
    }

    public func markDeleted(id: UUID, at date: Date) throws {
        guard let entity = try entity(id: id) else { throw DomainError.paymentNotFound }
        entity.deletedAt = date
        try context.saveOrThrow()
    }

    private func entity(id: UUID) throws -> PaymentEntity? {
        var descriptor = FetchDescriptor<PaymentEntity>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        return try context.fetchOrThrow(descriptor).first
    }
}
