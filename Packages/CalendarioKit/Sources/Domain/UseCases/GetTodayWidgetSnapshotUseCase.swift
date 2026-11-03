import Foundation

/// WID-01, WID-04: pagos de un día y su estado, sin dinero. Sirve también para la entrada de medianoche.
public struct GetTodayWidgetSnapshotUseCase {
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let calendar: Calendar

    public init(payments: any PaymentRepository, records: any PaymentRecordRepository, calendar: Calendar) {
        self.payments = payments
        self.records = records
        self.calendar = calendar
    }

    public func execute(for date: Date) throws -> TodaySnapshot {
        let period = YearMonth(containing: date, calendar: calendar)
        let statement = MonthStatementBuilder.build(
            period: period,
            payments: try payments.payments(includingDeleted: true),
            records: try records.records(in: period),
            calendar: calendar
        )
        let day = calendar.component(.day, from: date)
        // Como "Para hoy" en Inicio: los eliminados después de pagarlos solo quedan en el Historial.
        let items = statement.items(onEffectiveDay: day)
            .filter(\.paymentExists)
            .map { TodaySnapshot.Item(id: $0.id, name: $0.name, isPaid: $0.isPaid) }
        return TodaySnapshot(date: date, items: items)
    }
}
