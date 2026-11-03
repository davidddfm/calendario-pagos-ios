import Foundation

/// HER-08, MND-04, CAT-03, S-10: exporta los pagos activos con la moneda de la app.
public struct ExportPaymentsUseCase {
    private let payments: any PaymentRepository
    private let settings: any SettingsRepository
    private let exporter: any PaymentsExporting
    private let clock: any DateProviding

    public init(
        payments: any PaymentRepository,
        settings: any SettingsRepository,
        exporter: any PaymentsExporting,
        clock: any DateProviding
    ) {
        self.payments = payments
        self.settings = settings
        self.exporter = exporter
        self.clock = clock
    }

    public func execute() throws -> URL {
        let sorted = try payments.activePayments(clock: clock).sorted { lhs, rhs in
            if lhs.dayOfMonth != rhs.dayOfMonth { return lhs.dayOfMonth < rhs.dayOfMonth }
            return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        // El onboarding garantiza la moneda (MND-01); USD es el mismo respaldo que usa el formato.
        return try exporter.export(sorted, currency: settings.load().currency ?? .usd, date: clock.now)
    }
}
