import DesignSystem
import Features
import SwiftUI

/// Tres pestañas fijas, cada una con su propia pila de navegación (NAV-02) y un botón "+" (NAV-01).
struct MainTabView: View {
    let container: AppContainer
    @Bindable var router: AppRouter

    var body: some View {
        TabView(selection: $router.selectedTab) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $router.homePath) {
                    HomeView(
                        viewModel: container.makeHomeViewModel(),
                        onAddPayment: { router.sheet = .newPayment },
                        onSelectPayment: { router.sheet = .editPayment($0) },
                        onOpenFortnight: { router.homePath.append(.fortnight($0)) },
                        onOpenHistory: { router.homePath.append(.history) }
                    )
                    .toolbar { addPaymentButton }
                    .navigationDestination(for: AppRoute.self) { destination($0, path: $router.homePath) }
                }
            } label: {
                Label("Inicio", systemImage: "house")
            }

            // Calendario (iteración 4) y Perfil (iteración 3) todavía no tienen contenido propio.
            Tab(value: AppTab.calendar) {
                NavigationStack(path: $router.calendarPath) {
                    ContentUnavailableView("Calendario", systemImage: "calendar")
                        .navigationTitle("Calendario")
                        .toolbar { addPaymentButton }
                        .navigationDestination(for: AppRoute.self) { destination($0, path: $router.calendarPath) }
                }
            } label: {
                Label("Calendario", systemImage: "calendar")
            }

            Tab(value: AppTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    ContentUnavailableView("Perfil", systemImage: "person.crop.circle")
                        .navigationTitle("Perfil")
                        .toolbar { addPaymentButton }
                        .navigationDestination(for: AppRoute.self) { destination($0, path: $router.profilePath) }
                }
            } label: {
                Label("Perfil", systemImage: "person.crop.circle")
            }
        }
        .sheet(item: $router.sheet) { sheet in
            NavigationStack {
                PaymentFormView(viewModel: container.makePaymentFormViewModel(mode: sheet.formMode))
            }
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute, path: Binding<[AppRoute]>) -> some View {
        switch route {
        case .fortnight(let fortnight):
            FortnightDetailView(
                viewModel: container.makeFortnightViewModel(fortnight: fortnight),
                onSelectPayment: { router.sheet = .editPayment($0) })
        case .history:
            HistoryView(
                viewModel: container.makeHistoryViewModel(),
                onOpenMonth: { path.wrappedValue.append(.historyMonth($0)) })
        case .historyMonth(let period):
            HistoryMonthView(viewModel: container.makeHistoryMonthViewModel(period: period))
        }
    }

    private var addPaymentButton: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                router.sheet = .newPayment
            } label: {
                Label("Nuevo pago", systemImage: "plus")
            }
            .accessibilityIdentifier("addPayment")
        }
    }
}
