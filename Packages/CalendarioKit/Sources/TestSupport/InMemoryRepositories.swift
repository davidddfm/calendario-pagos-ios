import Domain
import Foundation

public final class InMemoryPaymentRepository: PaymentRepository {
    public private(set) var stored: [UUID: Payment]

    public init(_ payments: [Payment] = []) {
        stored = Dictionary(payments.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    public func payments(includingDeleted: Bool) throws -> [Payment] {
        stored.values.filter { includingDeleted || $0.deletedAt == nil }
    }

    public func payment(id: UUID) throws -> Payment? { stored[id] }
    public func insert(_ payment: Payment) throws { stored[payment.id] = payment }
    public func update(_ payment: Payment) throws { stored[payment.id] = payment }
    public func markDeleted(id: UUID, at date: Date) throws { stored[id]?.deletedAt = date }
}

public final class InMemoryPaymentRecordRepository: PaymentRecordRepository {
    public private(set) var stored: [PaymentRecord]

    public init(_ records: [PaymentRecord] = []) { stored = records }

    public func records(in period: YearMonth) throws -> [PaymentRecord] { stored.filter { $0.period == period } }

    public func records(from start: YearMonth, through end: YearMonth) throws -> [PaymentRecord] {
        stored.filter { $0.period >= start && $0.period <= end }
    }

    public func record(paymentID: UUID, period: YearMonth) throws -> PaymentRecord? {
        stored.first { $0.paymentID == paymentID && $0.period == period }
    }

    public func insert(_ record: PaymentRecord) throws {
        try delete(paymentID: record.paymentID, period: record.period)
        stored.append(record)
    }

    public func delete(paymentID: UUID, period: YearMonth) throws {
        stored.removeAll { $0.paymentID == paymentID && $0.period == period }
    }
}

public final class InMemorySettingsRepository: SettingsRepository {
    public private(set) var stored: AppSettings

    public init(_ settings: AppSettings = AppSettings()) { stored = settings }

    public func load() -> AppSettings { stored }
    public func save(_ settings: AppSettings) throws { stored = settings }
}

/// Registra los cambios notificados por los casos de uso.
public final class SpyChangeObserver: DataChangeObserving {
    public private(set) var changes: [DataChange] = []

    public init() {}

    public func dataDidChange(_ change: DataChange) { changes.append(change) }
}
