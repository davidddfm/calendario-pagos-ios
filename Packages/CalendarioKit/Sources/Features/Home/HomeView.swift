import DesignSystem
import Domain
import SwiftUI

/// Inicio: Para hoy, Análisis quincenal y lista completa con búsqueda (PAG-05 a PAG-08).
public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(DataChangeTracker.self) private var changes
    private let onAddPayment: () -> Void
    private let onSelectPayment: (UUID) -> Void
    private let onOpenFortnight: (Fortnight) -> Void
    private let onOpenHistory: () -> Void
    private let onOpenSettings: () -> Void
    private let exportFile: PaymentsCSVFile
    /// NOT-09: cada cambio lleva "Para hoy" a la vista.
    private let scrollToTodayRequest: Int

    public init(
        viewModel: HomeViewModel,
        onAddPayment: @escaping () -> Void,
        onSelectPayment: @escaping (UUID) -> Void,
        onOpenFortnight: @escaping (Fortnight) -> Void,
        onOpenHistory: @escaping () -> Void,
        onOpenSettings: @escaping () -> Void,
        exportFile: PaymentsCSVFile,
        scrollToTodayRequest: Int = 0
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onAddPayment = onAddPayment
        self.onSelectPayment = onSelectPayment
        self.onOpenFortnight = onOpenFortnight
        self.onOpenHistory = onOpenHistory
        self.onOpenSettings = onOpenSettings
        self.exportFile = exportFile
        self.scrollToTodayRequest = scrollToTodayRequest
    }

    public var body: some View {
        content
            .navigationTitle(Text("Inicio", bundle: .module))
            .toolbar {
                // Menú secundario (§1) con Exportar CSV (HER-10). Acerca de llega con su pantalla.
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button(action: onOpenHistory) {
                            Label {
                                Text("Historial de pagos", bundle: .module)
                            } icon: {
                                Image(systemName: "clock.arrow.circlepath")
                            }
                        }
                        Button(action: onOpenSettings) {
                            Label {
                                Text("Configuración", bundle: .module)
                            } icon: {
                                Image(systemName: "gearshape")
                            }
                        }
                        ExportCSVLink(file: exportFile)
                    } label: {
                        Label {
                            Text("Más opciones", bundle: .module)
                        } icon: {
                            Image(systemName: "ellipsis")
                        }
                    }
                    .accessibilityIdentifier("home.menu")
                }
            }
            .task(id: changes.version) { viewModel.load() }
            .confirmationDialog(
                Text("¿Eliminar este pago?", bundle: .module),
                isPresented: Binding(
                    get: { viewModel.paymentPendingDeletion != nil },
                    set: { if !$0 { viewModel.paymentPendingDeletion = nil } }),
                titleVisibility: .visible,
                presenting: viewModel.paymentPendingDeletion
            ) { _ in
                Button(role: .destructive) {
                    viewModel.confirmDeletion()
                } label: {
                    Text("Eliminar pago", bundle: .module)
                }
            } message: { item in
                Text(
                    "“\(item.name)” dejará de aparecer desde este mes. Los meses anteriores conservan su registro.",
                    bundle: .module)
            }
            .actionErrorAlert(error: viewModel.actionError, dismiss: viewModel.dismissActionError)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            LoadFailedView(error: error, retry: viewModel.load)
        case .loaded(let summary) where summary.isEmpty:
            welcome
        case .loaded(let summary):
            list(summary)
                .searchable(text: $viewModel.searchText, prompt: Text("Buscar pagos", bundle: .module))
        }
    }

    /// PAG-08
    private var welcome: some View {
        ContentUnavailableView {
            Label {
                Text("Te damos la bienvenida", bundle: .module)
            } icon: {
                Image(systemName: "calendar.badge.plus")
            }
        } description: {
            Text(
                "Registra una sola vez tus pagos mensuales: la app los repite cada mes en el mismo día y te ayuda a ver cuánto te queda.",
                bundle: .module)
        } actions: {
            Button(action: onAddPayment) {
                Text("Crear mi primer pago", bundle: .module)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func list(_ summary: HomeSummary) -> some View {
        List {
            if viewModel.isSearching {
                searchSection
            } else {
                todaySection(summary)
                fortnightSection(summary)
                Section {
                    ForEach(HomeRow.rows(summary.allItems, in: .all)) { row($0.item) }
                } header: {
                    Text("Todos los pagos", bundle: .module)
                }
            }
        }
        // NOT-09: "Para hoy" es la primera sección; una lista nueva arranca arriba. `ScrollViewReader` alrededor de
        // la `List` rompe su diff al borrar filas.
        .id(scrollToTodayRequest)
        .onChange(of: scrollToTodayRequest) { viewModel.searchText = "" }
    }

    @ViewBuilder
    private var searchSection: some View {
        let results = viewModel.searchResults
        if results.isEmpty {
            ContentUnavailableView.search(text: viewModel.searchText)
        } else {
            Section {
                ForEach(HomeRow.rows(results, in: .search)) { row($0.item) }
            } header: {
                Text("Resultados", bundle: .module)
            }
        }
    }

    private func todaySection(_ summary: HomeSummary) -> some View {
        Section {
            if summary.todayItems.isEmpty {
                Text("No tienes pagos para hoy.", bundle: .module)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(HomeRow.rows(summary.todayItems, in: .today)) { row($0.item) }
            }
        } header: {
            Text("Para hoy", bundle: .module)
        } footer: {
            Text(summary.today, format: .dateTime.weekday(.wide).day().month(.wide))
        }
    }

    private func fortnightSection(_ summary: HomeSummary) -> some View {
        Section {
            ForEach(summary.fortnights) { total in
                // PAG-06: tocar una quincena abre su detalle.
                Button {
                    onOpenFortnight(total.fortnight)
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(total.fortnight.title)
                            Text(total.fortnight.daysDescription)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        MoneyText(total.total)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.tertiary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Análisis quincenal", bundle: .module)
        }
    }

    private func row(_ item: MonthStatement.Item) -> some View {
        PaymentRow(
            item: item,
            onTogglePaid: { viewModel.togglePaid(item) },
            onSelect: { onSelectPayment(item.id) }
        )
        .swipeActions {
            Button(role: .destructive) {
                viewModel.requestDeletion(of: item)
            } label: {
                Label {
                    Text("Eliminar", bundle: .module)
                } icon: {
                    Image(systemName: "trash")
                }
            }
        }
    }
}

/// Un pago puede salir en "Para hoy" y en "Todos los pagos": cada fila necesita una identidad propia por sección,
/// o el diff de `List` falla al borrarlo.
private struct HomeRow: Identifiable {
    enum Section: String { case today, all, search }

    let section: Section
    let item: MonthStatement.Item

    var id: String { "\(section.rawValue)-\(item.id.uuidString)" }

    static func rows(_ items: [MonthStatement.Item], in section: Section) -> [HomeRow] {
        items.map { HomeRow(section: section, item: $0) }
    }
}

extension Fortnight {
    var title: LocalizedStringResource {
        switch self {
        case .first: LocalizedStringResource("Primera quincena", bundle: .features)
        case .second: LocalizedStringResource("Segunda quincena", bundle: .features)
        }
    }

    var daysDescription: LocalizedStringResource {
        switch self {
        case .first: LocalizedStringResource("Días 1 al 15", bundle: .features)
        case .second: LocalizedStringResource("Días 16 al 31", bundle: .features)
        }
    }
}
