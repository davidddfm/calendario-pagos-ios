public protocol SettingsRepository {
    /// Nunca falla: ante datos ilegibles devuelve valores por defecto válidos (§7.4).
    func load() -> AppSettings
    func save(_ settings: AppSettings) throws
}
