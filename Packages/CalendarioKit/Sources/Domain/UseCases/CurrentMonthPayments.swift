extension PaymentRepository {
    /// Pagos que existen en el mes actual: la base de Dashboard y herramientas (DAS, HER).
    func activePayments(clock: any DateProviding) throws -> [Payment] {
        let period = YearMonth(containing: clock.now, calendar: clock.calendar)
        return try payments(includingDeleted: false).active(in: period, calendar: clock.calendar)
    }
}
