import Domain
import Features
import Foundation
import Persistence
import SwiftData
import SystemServices

/// Única raíz de composición (§9.2): crea almacén, repositorios y casos de uso, y construye cada pantalla.
final class AppContainer {
    let tracker = DataChangeTracker()
    let settings: any SettingsRepository
    /// SEG-01 a SEG-04: una única instancia para toda la vida de la app.
    let appLock: AppLockController

    private let modelContainer: ModelContainer
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let clock: any DateProviding = SystemClock()
    private let sideEffects: AppSideEffects
    private let exporter: CSVPaymentExporter
    private let reminderScheduler: any ReminderScheduling
    private let authenticator: any DeviceOwnerAuthenticating

    init(storage: Storage = .appGroup) throws {
        modelContainer = try PersistenceStack.makeContainer(inMemory: storage.isInMemory)
        let context = modelContainer.mainContext
        let payments = SwiftDataPaymentRepository(context: context)
        guard let defaults = storage.defaults else { throw PersistenceError.storeUnavailable }

        self.payments = payments
        records = SwiftDataPaymentRecordRepository(context: context)
        // §7.4: si los ajustes son ilegibles y ya hay pagos, no se repite el onboarding.
        settings = UserDefaultsSettingsRepository(
            defaults: defaults,
            hasStoredPayments: { (try? payments.payments(includingDeleted: true).isEmpty) == false })
        sideEffects = AppSideEffects(tracker: tracker, widgets: storage.widgetRefresher)
        exporter = CSVPaymentExporter(timeZone: clock.calendar.timeZone)
        // §8.4: los CSV de sesiones anteriores no se conservan.
        try? exporter.removeExports()
        reminderScheduler = storage.reminderScheduler
        authenticator = storage.authenticator
        appLock = AppLockController(
            getSettings: GetSettingsUseCase(settings: settings),
            updateAppLock: UpdateAppLockSettingsUseCase(settings: settings),
            authenticator: authenticator,
            clock: clock)
        let reschedule = RescheduleRemindersUseCase(
            payments: payments, records: records, settings: settings, scheduler: reminderScheduler, clock: clock)
        // El cierre retiene el almacén: una reconciliación pendiente nunca lee un `ModelContext` sin contenedor.
        sideEffects.connect { [modelContainer] in
            withExtendedLifetime(modelContainer) {}
            try await reschedule.execute()
        }
    }

    /// NOT-04: renueva la ventana de avisos (al activar la app, al cambiar el reloj y en segundo plano).
    @discardableResult
    func reconcileReminders() -> Task<Void, Never> {
        sideEffects.reconcileReminders()
    }

    enum Storage {
        case appGroup
        #if DEBUG
            /// `-ui-testing` (§15): almacén en memoria y ajustes vacíos. No existe en Release (ADR-13).
            case uiTesting
        #endif

        var isInMemory: Bool {
            switch self {
            case .appGroup: false
            #if DEBUG
                case .uiTesting: true
            #endif
            }
        }

        var reminderScheduler: any ReminderScheduling {
            switch self {
            case .appGroup: UserNotificationReminderScheduler(route: DeepLink.today.rawValue)
            #if DEBUG
                case .uiTesting: UITestingReminderScheduler()
            #endif
            }
        }

        var widgetRefresher: any WidgetRefreshing {
            switch self {
            case .appGroup: WidgetCenterRefresher()
            #if DEBUG
                case .uiTesting: UITestingWidgetRefresher()
            #endif
            }
        }

        var authenticator: any DeviceOwnerAuthenticating {
            switch self {
            case .appGroup: LocalAuthenticationService()
            #if DEBUG
                case .uiTesting: UITestingAuthenticator()
            #endif
            }
        }

        var defaults: UserDefaults? {
            switch self {
            case .appGroup:
                return PersistenceStack.makeSharedDefaults()
            #if DEBUG
                case .uiTesting:
                    let suite = "ui-testing"
                    UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
                    return UserDefaults(suiteName: suite)
            #endif
            }
        }
    }
}

// MARK: - ScreenFactory

extension AppContainer: ScreenFactory {
    func makeOnboardingViewModel() -> OnboardingViewModel {
        OnboardingViewModel(completeOnboarding: CompleteOnboardingUseCase(settings: settings, observer: sideEffects))
    }

    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            getSummary: GetHomeSummaryUseCase(payments: payments, records: records, clock: clock),
            togglePaid: togglePaid,
            deletePayment: DeletePaymentUseCase(payments: payments, clock: clock, observer: sideEffects)
        )
    }

    func makeFortnightViewModel(fortnight: Fortnight) -> FortnightViewModel {
        FortnightViewModel(
            fortnight: fortnight,
            getDetail: GetFortnightDetailUseCase(
                payments: payments, records: records, settings: settings, clock: clock),
            togglePaid: togglePaid
        )
    }

    func makeHistoryViewModel() -> HistoryViewModel {
        HistoryViewModel(getOverview: GetHistoryOverviewUseCase(payments: payments, records: records, clock: clock))
    }

    func makeHistoryMonthViewModel(period: YearMonth) -> HistoryMonthViewModel {
        HistoryMonthViewModel(
            period: period,
            startDate: period.date(day: 1, calendar: clock.calendar),
            getStatement: GetMonthStatementUseCase(payments: payments, records: records, clock: clock),
            togglePaid: togglePaid
        )
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(getMonth: GetCalendarMonthUseCase(payments: payments, records: records, clock: clock))
    }

    func makeDayDetailViewModel(date: Date) -> DayDetailViewModel {
        DayDetailViewModel(
            date: date,
            getDetail: GetDayDetailUseCase(payments: payments, records: records, clock: clock),
            togglePaid: togglePaid
        )
    }

    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(getDashboard: GetDashboardUseCase(payments: payments, settings: settings, clock: clock))
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            getSettings: GetSettingsUseCase(settings: settings),
            updateSalary: UpdateSalaryUseCase(settings: settings, observer: sideEffects),
            changeCurrency: ChangeCurrencyUseCase(settings: settings, observer: sideEffects),
            updateReminders: UpdateReminderSettingsUseCase(settings: settings, observer: sideEffects),
            getReminderAuthorization: GetReminderAuthorizationUseCase(scheduler: reminderScheduler),
            requestReminderPermission: requestReminderPermission,
            updateAppLock: UpdateAppLockSettingsUseCase(settings: settings),
            authenticator: authenticator,
            calendar: clock.calendar
        )
    }

    func makeAffordabilityViewModel() -> AffordabilityViewModel {
        AffordabilityViewModel(
            evaluateAffordability: EvaluateAffordabilityUseCase(payments: payments, settings: settings, clock: clock))
    }

    func makeLeakDetectorViewModel() -> LeakDetectorViewModel {
        LeakDetectorViewModel(getReport: GetLeakReportUseCase(payments: payments, clock: clock))
    }

    func makeBudgetPlanViewModel() -> BudgetPlanViewModel {
        BudgetPlanViewModel(getPlan: GetBudgetPlanUseCase(settings: settings))
    }

    func makePaymentsCSVFile() -> PaymentsCSVFile {
        let export = ExportPaymentsUseCase(payments: payments, settings: settings, exporter: exporter, clock: clock)
        return PaymentsCSVFile { try export.execute() }
    }

    private var requestReminderPermission: RequestReminderPermissionUseCase {
        RequestReminderPermissionUseCase(settings: settings, scheduler: reminderScheduler, observer: sideEffects)
    }

    private var togglePaid: TogglePaymentPaidUseCase {
        TogglePaymentPaidUseCase(payments: payments, records: records, clock: clock, observer: sideEffects)
    }

    func makePaymentFormViewModel(mode: PaymentFormViewModel.Mode) -> PaymentFormViewModel {
        PaymentFormViewModel(
            mode: mode,
            defaultDay: clock.calendar.component(.day, from: clock.now),
            createPayment: CreatePaymentUseCase(payments: payments, clock: clock, observer: sideEffects),
            updatePayment: UpdatePaymentUseCase(payments: payments, clock: clock, observer: sideEffects),
            deletePayment: DeletePaymentUseCase(payments: payments, clock: clock, observer: sideEffects),
            getPayment: GetPaymentUseCase(payments: payments),
            shouldOfferReminderPermission: ShouldOfferReminderPermissionUseCase(
                settings: settings, scheduler: reminderScheduler),
            requestReminderPermission: requestReminderPermission
        )
    }
}
