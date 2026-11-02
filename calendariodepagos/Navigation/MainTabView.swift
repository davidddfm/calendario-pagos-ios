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
                NavigationStack {
                    HomeView(
                        viewModel: container.makeHomeViewModel(),
                        onAddPayment: { router.sheet = .newPayment },
                        onSelectPayment: { router.sheet = .editPayment($0) }
                    )
                    .toolbar { addPaymentButton }
                }
            } label: {
                Label("Inicio", systemImage: "house")
            }

            // Calendario (iteración 4) y Perfil (iteración 3) todavía no tienen contenido propio.
            Tab(value: AppTab.calendar) {
                NavigationStack {
                    ContentUnavailableView("Calendario", systemImage: "calendar")
                        .navigationTitle("Calendario")
                        .toolbar { addPaymentButton }
                }
            } label: {
                Label("Calendario", systemImage: "calendar")
            }

            Tab(value: AppTab.profile) {
                NavigationStack {
                    ContentUnavailableView("Perfil", systemImage: "person.crop.circle")
                        .navigationTitle("Perfil")
                        .toolbar { addPaymentButton }
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
