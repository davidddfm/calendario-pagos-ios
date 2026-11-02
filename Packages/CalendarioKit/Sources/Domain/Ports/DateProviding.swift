import Foundation

/// Fecha actual y calendario inyectados (§8.5). Ninguna regla usa `Date()` ni `Calendar.current`.
public protocol DateProviding: Sendable {
    var now: Date { get }
    var calendar: Calendar { get }
}
