/// NOT-06: estado del permiso para Ajustes.
public struct GetReminderAuthorizationUseCase {
    private let scheduler: any ReminderScheduling

    public init(scheduler: any ReminderScheduling) {
        self.scheduler = scheduler
    }

    nonisolated(nonsending) public func execute() async -> ReminderAuthorization {
        await scheduler.authorizationStatus()
    }
}

/// S-08: tras guardar el primer pago se explica el permiso, una sola vez y solo si aún no se decidió.
public struct ShouldOfferReminderPermissionUseCase {
    private let settings: any SettingsRepository
    private let scheduler: any ReminderScheduling

    public init(settings: any SettingsRepository, scheduler: any ReminderScheduling) {
        self.settings = settings
        self.scheduler = scheduler
    }

    nonisolated(nonsending) public func execute() async -> Bool {
        let reminders = settings.load().reminders
        guard reminders.isEnabled, !reminders.hasOfferedPermission else { return false }
        return await scheduler.authorizationStatus() == .notDetermined
    }
}

/// NOT-06: pide el permiso (o registra "Ahora no") y no vuelve a ofrecer la explicación.
public struct RequestReminderPermissionUseCase {
    private let settings: any SettingsRepository
    private let scheduler: any ReminderScheduling
    private let observer: any DataChangeObserving

    public init(
        settings: any SettingsRepository, scheduler: any ReminderScheduling, observer: any DataChangeObserving
    ) {
        self.settings = settings
        self.scheduler = scheduler
        self.observer = observer
    }

    /// - Parameter accepted: `false` = "Ahora no": no se muestra el diálogo del sistema.
    @discardableResult
    nonisolated(nonsending) public func execute(accepted: Bool = true) async throws -> ReminderAuthorization {
        var current = settings.load()
        current.reminders.hasOfferedPermission = true
        try settings.save(current)
        guard accepted else { return await scheduler.authorizationStatus() }
        _ = await scheduler.requestAuthorization()
        // Con el permiso concedido se programan los avisos.
        observer.dataDidChange(.reminderSettings)
        return await scheduler.authorizationStatus()
    }
}
