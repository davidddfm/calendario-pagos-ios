import Domain
import Foundation

public struct TestDateError: Error {}

extension Calendar {
    /// §15: calendario fijo para pruebas (gregoriano, UTC, es_MX). Nunca `Calendar.current`.
    public static var testGregorian: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "es_MX")
        calendar.timeZone = TimeZone(identifier: "UTC") ?? TimeZone(secondsFromGMT: 0) ?? calendar.timeZone
        return calendar
    }

    public func date(year: Int, month: Int, day: Int, hour: Int = 12, minute: Int = 0) throws -> Date {
        let components = DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)
        guard let date = self.date(from: components) else { throw TestDateError() }
        return date
    }
}
