/// NOT-01 a NOT-08 (§11.8): reconcilia los avisos pendientes con los datos actuales.
public struct RescheduleRemindersUseCase {
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let settings: any SettingsRepository
    private let scheduler: any ReminderScheduling
    private let clock: any DateProviding

    public init(
        payments: any PaymentRepository,
        records: any PaymentRecordRepository,
        settings: any SettingsRepository,
        scheduler: any ReminderScheduling,
        clock: any DateProviding
    ) {
        self.payments = payments
        self.records = records
        self.settings = settings
        self.scheduler = scheduler
        self.clock = clock
    }

    /// Lee los datos en el aislamiento de quien llama (los repositorios no son `Sendable`).
    nonisolated(nonsending) public func execute() async throws {
        let reminders = settings.load().reminders
        guard reminders.isEnabled else {  // NOT-05
            await scheduler.removeAll()
            return
        }
        guard await scheduler.authorizationStatus() == .authorized else {  // NOT-06
            await scheduler.removeAll()
            return
        }
        let now = clock.now
        let plans = ReminderPlanner.plan(
            now: now,
            settings: reminders,
            payments: try payments.payments(includingDeleted: true),
            currentMonthRecords: try records.records(in: YearMonth(containing: now, calendar: clock.calendar)),
            calendar: clock.calendar
        )
        try await scheduler.replaceAll(with: plans)
    }
}
