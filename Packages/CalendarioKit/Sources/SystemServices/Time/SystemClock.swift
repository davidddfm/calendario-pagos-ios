import Domain
import Foundation

/// §8.5: calendario gregoriano con la zona horaria y la configuración regional del usuario.
public struct SystemClock: DateProviding {
    public init() {}

    public var now: Date { Date.now }

    public var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale.autoupdatingCurrent
        calendar.timeZone = TimeZone.autoupdatingCurrent
        return calendar
    }
}
