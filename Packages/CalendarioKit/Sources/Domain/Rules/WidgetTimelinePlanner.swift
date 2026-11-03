import Foundation

/// WID-04: cuándo cambia el widget. Una entrada ahora y otra a medianoche; se recarga a medianoche.
public enum WidgetTimelinePlanner {
    /// Reintento cuando no se pudo leer el almacén o calcular la medianoche (§7.2).
    public static let retryInterval: TimeInterval = 15 * 60

    public struct Plan: Equatable, Sendable {
        public let entryDates: [Date]
        public let reloadDate: Date
    }

    public static func plan(now: Date, calendar: Calendar) -> Plan {
        // Día siguiente con `Calendar` (no 86 400 s) para respetar los cambios de horario.
        guard let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) else {
            return retry(now: now)
        }
        return Plan(entryDates: [now, midnight], reloadDate: midnight)
    }

    public static func retry(now: Date) -> Plan {
        Plan(entryDates: [now], reloadDate: now.addingTimeInterval(retryInterval))
    }
}
