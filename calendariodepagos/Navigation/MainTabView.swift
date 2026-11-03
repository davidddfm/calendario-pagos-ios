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
                        onOpenHistory: { router.homePath.append(.history) },
                        onOpenSettings: { router.homePath.append(.settings) },
                        exportFile: container.makePaymentsCSVFile(),
                        scrollToTodayRequest: router.homeScrollRequest
                    )
                    .toolbar { addPaymentButton }
                    .navigationDestination(for: AppRoute.self) { destination($0, path: $router.homePath) }
                }
            } label: {
                Label("Inicio", systemImage: "house")
            }

            Tab(value: AppTab.calendar) {
                NavigationStack(path: $router.calendarPath) {
                    CalendarView(
                        viewModel: container.makeCalendarViewModel(),
                        onOpenDay: { router.calendarPath.append(.dayDetail($0)) }
                    )
                    .toolbar {
                        // CAL-07
                        ToolbarItem(placement: .topBarLeading) {
                            ToolsMenu(exportFile: container.makePaymentsCSVFile()) {
                                router.calendarPath.append(AppRoute($0))
                            }
                        }
                        addPaymentButton
                    }
                    .navigationDestination(for: AppRoute.self) { destination($0, path: $router.calendarPath) }
                }
            } label: {
                Label("Calendario", systemImage: "calendar")
            }

            Tab(value: AppTab.profile) {
                NavigationStack(path: $router.profilePath) {
                    DashboardView(
                        viewModel: container.makeDashboardViewModel(),
                        onConfigureSalary: { router.profilePath.append(.settings) },
                        onOpenHistory: { router.profilePath.append(.history) }
                    )
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
                onSelectPayment: { router.sheet = .editPayment($0) },
                onConfigureSalary: { path.wrappedValue.append(.settings) })
        case .dayDetail(let date):
            DayDetailView(
                viewModel: container.makeDayDetailViewModel(date: date),
                onSelectPayment: { router.sheet = .editPayment($0) })
        case .history:
            HistoryView(
                viewModel: container.makeHistoryViewModel(),
                onOpenMonth: { path.wrappedValue.append(.historyMonth($0)) })
        case .historyMonth(let period):
            HistoryMonthView(viewModel: container.makeHistoryMonthViewModel(period: period))
        case .settings:
            SettingsView(viewModel: container.makeSettingsViewModel())
        case .affordability:
            AffordabilityView(
                viewModel: container.makeAffordabilityViewModel(),
                onConfigureSalary: { path.wrappedValue.append(.settings) })
        case .leakDetector:
            LeakDetectorView(viewModel: container.makeLeakDetectorViewModel())
        case .budgetPlan:
            BudgetPlanView(
                viewModel: container.makeBudgetPlanViewModel(),
                onConfigureSalary: { path.wrappedValue.append(.settings) })
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
