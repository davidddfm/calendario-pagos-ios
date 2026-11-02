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

    private let modelContainer: ModelContainer
    private let payments: any PaymentRepository
    private let records: any PaymentRecordRepository
    private let clock: any DateProviding = SystemClock()
    private let sideEffects: AppSideEffects

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
        sideEffects = AppSideEffects(tracker: tracker)
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
            getPayment: GetPaymentUseCase(payments: payments)
        )
    }
}
