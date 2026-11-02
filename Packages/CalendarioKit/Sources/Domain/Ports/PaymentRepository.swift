import Foundation

public protocol PaymentRepository {
    func payments(includingDeleted: Bool) throws -> [Payment]
    func payment(id: UUID) throws -> Payment?
    func insert(_ payment: Payment) throws
    func update(_ payment: Payment) throws
    /// ADR-07: borrado lógico.
    func markDeleted(id: UUID, at date: Date) throws
}
