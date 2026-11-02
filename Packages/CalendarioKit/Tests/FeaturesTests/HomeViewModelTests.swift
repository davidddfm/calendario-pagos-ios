import Domain
import Foundation
import TestSupport
import Testing

@testable import Features

@Suite("PAG-04 / PAG-05 · Inicio")
struct HomeViewModelTests {
    let payments: InMemoryPaymentRepository
    let records = InMemoryPaymentRecordRepository()
    let clock: FixedClock
    let viewModel: HomeViewModel

    init() throws {
        let created = try Calendar.testGregorian.date(year: 2026, month: 1, day: 1)
        payments = InMemoryPaymentRepository([
            Payment.fixture(name: "Teléfono", day: 3, createdAt: created),
            Payment.fixture(name: "Préstamo coche", day: 10, createdAt: created),
            Payment.fixture(name: "Internet", day: 20, createdAt: created),
        ])
        clock = FixedClock(now: try Calendar.testGregorian.date(year: 2026, month: 10, day: 10))
        viewModel = HomeViewModel(
            getSummary: GetHomeSummaryUseCase(payments: payments, records: records, clock: clock),
            togglePaid: TogglePaymentPaidUseCase(
                payments: payments, records: records, clock: clock, observer: SpyChangeObserver()),
            deletePayment: DeletePaymentUseCase(payments: payments, clock: clock, observer: SpyChangeObserver()))
    }

    @Test func loads() throws {
        viewModel.load()
        let summary = try #require(viewModel.state.value)
        #expect(summary.todayItems.map(\.name) == ["Préstamo coche"])
        #expect(summary.allItems.count == 3)
    }

    @Test(
        "PAG-05 · Filtra mientras se escribe, sin mayúsculas ni acentos",
        arguments: [
            ("telefono", ["Teléfono"]),
            ("PRESTAMO", ["Préstamo coche"]),
            ("e", ["Teléfono", "Préstamo coche", "Internet"]),
            ("luz", []),
        ])
    func search(query: String, expected: [String]) {
        viewModel.load()
        viewModel.searchText = query
        #expect(viewModel.isSearching)
        #expect(viewModel.searchResults.map(\.name) == expected)
    }

    @Test("Una búsqueda de solo espacios no cuenta como búsqueda")
    func blankSearch() {
        viewModel.searchText = "   "
        #expect(!viewModel.isSearching)
    }

    @Test("PAG-04 · Solo se elimina tras confirmar")
    func deletionNeedsConfirmation() throws {
        viewModel.load()
        let item = try #require(viewModel.state.value?.allItems.first)

        viewModel.requestDeletion(of: item)
        #expect(try payments.payments(includingDeleted: false).count == 3)

        viewModel.confirmDeletion()
        #expect(viewModel.paymentPendingDeletion == nil)
        #expect(try payments.payment(id: item.id)?.deletedAt != nil)
    }

    @Test("MAR-01 · Marcar desde Inicio actualiza el estado en pantalla")
    func togglePaid() throws {
        viewModel.load()
        let item = try #require(viewModel.state.value?.todayItems.first)
        viewModel.togglePaid(item)
        #expect(viewModel.state.value?.todayItems.first?.isPaid == true)
        #expect(records.stored.count == 1)
        viewModel.togglePaid(try #require(viewModel.state.value?.todayItems.first))
        #expect(viewModel.state.value?.todayItems.first?.isPaid == false)
    }

    @Test("Confirmar sin una eliminación pendiente no hace nada")
    func confirmWithoutPending() throws {
        viewModel.confirmDeletion()
        #expect(try payments.payments(includingDeleted: false).count == 3)
    }
}

@Suite("MND-01 · Onboarding de moneda")
struct OnboardingViewModelTests {
    @Test func requiresSelection() throws {
        let settings = InMemorySettingsRepository()
        let viewModel = OnboardingViewModel(
            completeOnboarding: CompleteOnboardingUseCase(settings: settings, observer: SpyChangeObserver()))

        #expect(!viewModel.canContinue)
        viewModel.complete()
        #expect(settings.stored.needsOnboarding)

        viewModel.selectedCurrency = .eur
        viewModel.complete()
        #expect(settings.stored.currency == .eur)
        #expect(!settings.stored.needsOnboarding)
    }
}
