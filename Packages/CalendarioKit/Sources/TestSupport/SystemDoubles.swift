import Domain
import Foundation
import Synchronization

/// Reloj que las pruebas pueden avanzar (bloqueo, SEG-02).
public final class MutableClock: DateProviding {
    private let date: Mutex<Date>
    public let calendar: Calendar

    public init(now: Date, calendar: Calendar = .testGregorian) {
        date = Mutex(now)
        self.calendar = calendar
    }

    public var now: Date { date.withLock { $0 } }

    public func advance(by seconds: TimeInterval) {
        date.withLock { $0 = $0.addingTimeInterval(seconds) }
    }
}

/// Registra lo que se pide al programador de avisos (NOT).
public actor SpyReminderScheduler: ReminderScheduling {
    public var status: ReminderAuthorization
    /// Estado tras `requestAuthorization()`.
    public let statusAfterRequest: ReminderAuthorization
    public private(set) var scheduled: [ReminderPlan]?
    public private(set) var removeAllCount = 0
    public private(set) var requestCount = 0

    public init(status: ReminderAuthorization, statusAfterRequest: ReminderAuthorization = .authorized) {
        self.status = status
        self.statusAfterRequest = statusAfterRequest
    }

    public func authorizationStatus() async -> ReminderAuthorization { status }

    public func requestAuthorization() async -> Bool {
        requestCount += 1
        status = statusAfterRequest
        return status == .authorized
    }

    public func replaceAll(with plans: [ReminderPlan]) async throws { scheduled = plans }

    public func removeAll() async {
        removeAllCount += 1
        scheduled = []
    }
}

/// Autenticación del dueño con respuestas fijas (SEG).
public final class StubAuthenticator: DeviceOwnerAuthenticating {
    private let state: Mutex<(availability: DeviceOwnerAuthAvailability, result: DeviceOwnerAuthResult, count: Int)>

    public init(availability: DeviceOwnerAuthAvailability = .available, result: DeviceOwnerAuthResult = .success) {
        state = Mutex((availability, result, 0))
    }

    public var authenticationCount: Int { state.withLock { $0.count } }

    public func set(availability: DeviceOwnerAuthAvailability) { state.withLock { $0.availability = availability } }
    public func set(result: DeviceOwnerAuthResult) { state.withLock { $0.result = result } }

    public func availability() -> DeviceOwnerAuthAvailability { state.withLock { $0.availability } }
    public func biometry() -> DeviceBiometry { .faceID }

    public func authenticate(reason: String) async -> DeviceOwnerAuthResult {
        state.withLock {
            $0.count += 1
            return $0.result
        }
    }
}
