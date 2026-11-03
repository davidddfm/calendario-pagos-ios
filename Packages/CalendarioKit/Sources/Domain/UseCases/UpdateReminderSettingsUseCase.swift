/// NOT-02 / NOT-05: la reprogramación la dispara el observador (§9.4).
public struct UpdateReminderSettingsUseCase {
    private let settings: any SettingsRepository
    private let observer: any DataChangeObserving

    public init(settings: any SettingsRepository, observer: any DataChangeObserving) {
        self.settings = settings
        self.observer = observer
    }

    public func execute(isEnabled: Bool, hour: Int, minute: Int) throws {
        guard (0...23).contains(hour), (0...59).contains(minute) else { throw DomainError.invalidReminderTime }
        var current = settings.load()
        current.reminders.isEnabled = isEnabled
        current.reminders.hour = hour
        current.reminders.minute = minute
        try settings.save(current)
        observer.dataDidChange(.reminderSettings)
    }
}
