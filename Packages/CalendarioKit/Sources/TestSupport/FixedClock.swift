import Domain
import Foundation

/// §15: reloj fijo para pruebas.
public struct FixedClock: DateProviding {
    public var now: Date
    public var calendar: Calendar

    public init(now: Date, calendar: Calendar = .testGregorian) {
        self.now = now
        self.calendar = calendar
    }
}
