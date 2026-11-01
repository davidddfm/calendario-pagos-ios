import Foundation

/// Construye el `MonthStatement` de un mes a partir de los pagos y sus registros (ADR-05: estado derivado).
public enum MonthStatementBuilder {
    /// - Parameters:
    ///   - payments: todos los pagos, **incluidos los eliminados**, para ubicar los registros de pagos borrados.
    ///   - records: registros del mes; los de otros meses se ignoran.
    public static func build(
        period: YearMonth,
        payments: [Payment],
        records: [PaymentRecord],
        calendar: Calendar
    ) -> MonthStatement {
        var recordsByPayment: [UUID: PaymentRecord] = [:]
        for record in records where record.period == period {
            // Ante duplicados (no deberían existir por `#Unique`), gana el primero.
            recordsByPayment[record.paymentID] = recordsByPayment[record.paymentID] ?? record
        }

        var items: [MonthStatement.Item] = []
        var listed = Set<UUID>()

        for payment in payments where payment.isActive(in: period, calendar: calendar) {
            guard listed.insert(payment.id).inserted else { continue }
            let record = recordsByPayment[payment.id]
            // MAR-04: un pago marcado se muestra con su instantánea; uno pendiente, con sus datos actuales (S-02).
            items.append(
                MonthStatement.Item(
                    id: payment.id,
                    name: record?.name ?? payment.name,
                    category: record?.category ?? payment.category,
                    scheduledDay: payment.dayOfMonth,
                    effectiveDay: period.effectiveDay(for: payment.dayOfMonth),
                    currentAmount: payment.amount,
                    record: record
                ))
        }

        // Registros cuyo pago ya no está activo en el mes: se muestran solo con la instantánea.
        let paymentsByID = Dictionary(payments.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for record in recordsByPayment.values where !listed.contains(record.paymentID) {
            // Sin el pago (almacén incompleto) no hay día programado; se ubica el día 1.
            let scheduledDay = paymentsByID[record.paymentID]?.dayOfMonth ?? 1
            items.append(
                MonthStatement.Item(
                    id: record.paymentID,
                    name: record.name,
                    category: record.category,
                    scheduledDay: scheduledDay,
                    effectiveDay: period.effectiveDay(for: scheduledDay),
                    currentAmount: nil,
                    record: record
                ))
        }

        items.sort { lhs, rhs in
            if lhs.effectiveDay != rhs.effectiveDay { return lhs.effectiveDay < rhs.effectiveDay }
            let order = lhs.name.localizedStandardCompare(rhs.name)
            if order != .orderedSame { return order == .orderedAscending }
            return lhs.id.uuidString < rhs.id.uuidString
        }
        return MonthStatement(period: period, items: items)
    }
}
