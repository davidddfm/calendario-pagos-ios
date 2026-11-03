#if DEBUG
    import Domain

    /// `-ui-testing` (§15): sin diálogos del sistema que bloqueen las pruebas. No existe en Release (ADR-13).
    struct UITestingReminderScheduler: ReminderScheduling {
        func authorizationStatus() async -> ReminderAuthorization { .authorized }
        func requestAuthorization() async -> Bool { true }
        func replaceAll(with plans: [ReminderPlan]) async throws {}
        func removeAll() async {}
    }

    /// El simulador no tiene código; esta versión permite probar el flujo de bloqueo (SEG-01 a SEG-03).
    struct UITestingAuthenticator: DeviceOwnerAuthenticating {
        func availability() -> DeviceOwnerAuthAvailability { .available }
        func biometry() -> DeviceBiometry { .faceID }
        /// La pausa deja ver la pantalla de bloqueo antes de desbloquear (SEG-03).
        func authenticate(reason: String) async -> DeviceOwnerAuthResult {
            try? await Task.sleep(for: .seconds(2))
            return .success
        }
    }
#endif
