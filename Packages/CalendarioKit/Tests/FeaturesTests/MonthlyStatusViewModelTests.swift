import Domain
import Foundation
import TestSupport
import Testing

@testable import Features

@Suite("QUI / HIS · ViewModels de quincena e historial")
struct MonthlyStatusViewModelTests {
    let calendar = Calendar.testGregorian
    let payments: InMemoryPaymentRepository
    let records = InMemoryPaymentRecordRepository()
    let clock: FixedClock
    let rent: Payment

    init() throws {
        rent = Payment.fixture(
            name: "Renta", amount: Money(major: 400), day: 1,
            createdAt: try Calendar.testGregorian.date(year: 2026, month: 8, day: 1))
        payments = InMemoryPaymentRepository([rent])
        clock = FixedClock(now: try Calendar.testGregorian.date(year: 2026, month: 10, day: 10))
    }

    private var toggle: TogglePaymentPaidUseCase {
        TogglePaymentPaidUseCase(payments: payments, records: records, clock: clock, observer: SpyChangeObserver())
    }

    @Test("QUI-02 / QUI-03 · Saldo de la quincena y casilla")
    func fortnight() throws {
        let settings = InMemorySettingsRepository(AppSettings(currency: .usd, monthlySalary: Money(major: 1_000)))
        let viewModel = FortnightViewModel(
            fortnight: .first,
            getDetail: GetFortnightDetailUseCase(
                payments: payments, records: records, settings: settings, clock: clock),
            togglePaid: toggle)

        viewModel.load()
        let detail = try #require(viewModel.state.value)
        #expect(detail.remaining == Money(major: 100))

        viewModel.togglePaid(try #require(detail.items.first))
        #expect(viewModel.state.value?.items.first?.isPaid == true)
    }

    @Test("HIS-04 · Corregir un mes pasado no toca el mes actual")
    func historyMonth() throws {
        let september = try YearMonth.make(2026, 9)
        let viewModel = HistoryMonthViewModel(
            period: september, startDate: nil,
            getStatement: GetMonthStatementUseCase(payments: payments, records: records, clock: clock),
            togglePaid: toggle)

        viewModel.load()
        #expect(viewModel.state.value?.pending.map(\.name) == ["Renta"])
        viewModel.togglePaid(try #require(viewModel.state.value?.pending.first))

        #expect(viewModel.state.value?.paid.map(\.name) == ["Renta"])
        #expect(try records.records(in: september).count == 1)
        #expect(try records.records(in: .make(2026, 10)).isEmpty)
    }

    @Test("HIS-01 · El historial lista los meses desde el primer pago")
    func history() throws {
        let viewModel = HistoryViewModel(
            getOverview: GetHistoryOverviewUseCase(payments: payments, records: records, clock: clock))
        viewModel.load()
        #expect(viewModel.state.value?.months.map(\.period.month) == [10, 9, 8])
    }
}
