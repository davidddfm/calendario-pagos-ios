import Foundation

/// Aviso de un día concreto (ADR-09). Nunca lleva montos (NOT-07).
public struct ReminderPlan: Equatable, Sendable {
    /// "reminder.2026-10-30": uno por día como máximo (NOT-03).
    public let identifier: String
    /// Año, mes, día, hora y minuto.
    public let fireDate: DateComponents
    /// S-06: solo los pagos pendientes del día.
    public let pendingNames: [String]

    public init(identifier: String, fireDate: DateComponents, pendingNames: [String]) {
        self.identifier = identifier
        self.fireDate = fireDate
        self.pendingNames = pendingNames
    }
}

/// Calcula la ventana deslizante de avisos (NOT-01 a NOT-08).
public enum ReminderPlanner {
    /// Menor que los 64 avisos pendientes que permite iOS.
    public static let horizonDays = 60

    /// - Parameters:
    ///   - payments: pagos (pueden incluir eliminados; se filtran por mes).
    ///   - currentMonthRecords: registros del mes de `now`, para omitir lo ya pagado (NOT-08).
    public static func plan(
        now: Date,
        settings: ReminderSettings,
        payments: [Payment],
        currentMonthRecords: [PaymentRecord],
        calendar: Calendar
    ) -> [ReminderPlan] {
        guard settings.isEnabled else { return [] }  // NOT-05

        let currentPeriod = YearMonth(containing: now, calendar: calendar)
        let paidIDs = Set(currentMonthRecords.filter { $0.period == currentPeriod }.map(\.paymentID))
        let startOfToday = calendar.startOfDay(for: now)

        var plans: [ReminderPlan] = []
        var activeByPeriod: [YearMonth: [Payment]] = [:]

        for offset in 0..<horizonDays {
            guard
                let day = calendar.date(byAdding: .day, value: offset, to: startOfToday),
                let fire = calendar.date(bySettingHour: settings.hour, minute: settings.minute, second: 0, of: day),
                fire > now
            else { continue }

            let period = YearMonth(containing: day, calendar: calendar)
            let dayNumber = calendar.component(.day, from: day)
            let active = activeByPeriod[period] ?? payments.active(in: period, calendar: calendar)
            activeByPeriod[period] = active

            // PAG-07: el pago del 31 avisa el último día de los meses cortos.
            var due = active.filter { period.effectiveDay(for: $0.dayOfMonth) == dayNumber }
            guard !due.isEmpty else { continue }  // NOT-03
            if period == currentPeriod {
                due.removeAll { paidIDs.contains($0.id) }
                guard !due.isEmpty else { continue }  // NOT-08
            }

            let names = due.map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            plans.append(
                ReminderPlan(
                    identifier: identifier(year: period.year, month: period.month, day: dayNumber),
                    fireDate: DateComponents(
                        year: period.year, month: period.month, day: dayNumber,
                        hour: settings.hour, minute: settings.minute),
                    pendingNames: names
                ))
        }
        return plans
    }

    static func identifier(year: Int, month: Int, day: Int) -> String {
        let month = month < 10 ? "0\(month)" : "\(month)"
        let day = day < 10 ? "0\(day)" : "\(day)"
        return "reminder.\(year)-\(month)-\(day)"
    }
}
