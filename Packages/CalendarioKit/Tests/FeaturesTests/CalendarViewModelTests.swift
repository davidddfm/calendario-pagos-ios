import Domain
import Foundation
import TestSupport
import Testing

@testable import Features

@Suite("CAL · ViewModels del Calendario")
struct CalendarViewModelTests {
    let calendar = Calendar.testGregorian
    let payments: InMemoryPaymentRepository
    let records = InMemoryPaymentRecordRepository()
    let clock: FixedClock
    let rent: Payment

    init() throws {
        rent = Payment.fixture(
            name: "Renta", amount: Money(major: 400), day: 1,
            createdAt: try Calendar.testGregorian.date(year: 2026, month: 1, day: 1))
        payments = InMemoryPaymentRepository([rent])
        clock = FixedClock(now: try Calendar.testGregorian.date(year: 2026, month: 12, day: 10))
    }

    private var toggle: TogglePaymentPaidUseCase {
        TogglePaymentPaidUseCase(payments: payments, records: records, clock: clock, observer: SpyChangeObserver())
    }

    @Test("CAL-02 · Navegar sin límite cruzando el año y volver a hoy")
    func navigation() throws {
        let viewModel = CalendarViewModel(
            getMonth: GetCalendarMonthUseCase(payments: payments, records: records, clock: clock))
        viewModel.load()
        #expect(viewModel.isShowingCurrentMonth)

        viewModel.showNextMonth()
        #expect(viewModel.period == (try .make(2027, 1)))
        #expect(viewModel.state.value?.period == (try .make(2027, 1)))
        #expect(!viewModel.isShowingCurrentMonth)

        viewModel.showPreviousMonth()
        viewModel.showPreviousMonth()
        #expect(viewModel.period == (try .make(2026, 11)))

        viewModel.showCurrentMonth()
        #expect(viewModel.period == (try .make(2026, 12)))
    }

    @Test("CAL-04 · Marcar desde el día del mes actual")
    func toggleToday() throws {
        let viewModel = DayDetailViewModel(
            date: try calendar.date(year: 2026, month: 12, day: 1),
            getDetail: GetDayDetailUseCase(payments: payments, records: records, clock: clock),
            togglePaid: toggle)
        viewModel.load()
        viewModel.togglePaid(try #require(viewModel.state.value?.items.first))
        #expect(viewModel.state.value?.paidCount == 1)
    }

    @Test("CAL-05 · En otros meses no se marca")
    func noToggleOtherMonth() throws {
        let viewModel = DayDetailViewModel(
            date: try calendar.date(year: 2026, month: 11, day: 1),
            getDetail: GetDayDetailUseCase(payments: payments, records: records, clock: clock),
            togglePaid: toggle)
        viewModel.load()
        viewModel.togglePaid(try #require(viewModel.state.value?.items.first))
        #expect(records.stored.isEmpty)
    }
}
