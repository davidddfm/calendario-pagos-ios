/// Estado de un mes para el Calendario (§11.5): los meses pasados combinan registros y pagos activos;
/// los futuros proyectan los pagos activos hoy.
struct CalendarStatementSource {
    let payments: any PaymentRepository
    let records: any PaymentRecordRepository
    let clock: any DateProviding

    var currentPeriod: YearMonth { YearMonth(containing: clock.now, calendar: clock.calendar) }

    func statement(for period: YearMonth) throws -> MonthStatement {
        let statement = MonthStatementBuilder.build(
            period: period,
            payments: try payments.payments(includingDeleted: true),
            records: try records.records(in: period),
            calendar: clock.calendar
        )
        // Como en Inicio, el mes actual solo muestra pagos vigentes; los meses pasados conservan los eliminados
        // después de pagarlos, igual que el Historial.
        guard period == currentPeriod else { return statement }
        return MonthStatement(period: period, items: statement.items.filter(\.paymentExists))
    }
}
