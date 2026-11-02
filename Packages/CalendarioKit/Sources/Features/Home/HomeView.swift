import DesignSystem
import Domain
import SwiftUI

/// Inicio: Para hoy, Análisis quincenal y lista completa con búsqueda (PAG-05 a PAG-08).
public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    @Environment(DataChangeTracker.self) private var changes
    private let onAddPayment: () -> Void
    private let onSelectPayment: (UUID) -> Void

    public init(
        viewModel: HomeViewModel,
        onAddPayment: @escaping () -> Void,
        onSelectPayment: @escaping (UUID) -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onAddPayment = onAddPayment
        self.onSelectPayment = onSelectPayment
    }

    public var body: some View {
        content
            .navigationTitle(Text("Inicio", bundle: .module))
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
            .alert(
                Text("No se pudo eliminar", bundle: .module),
                isPresented: Binding(
                    get: { viewModel.actionError != nil }, set: { if !$0 { viewModel.dismissActionError() } }),
                presenting: viewModel.actionError
            ) { _ in
            } message: { error in
                Text(verbatim: error.message)
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .failed(let error):
            ContentUnavailableView {
                Label {
                    Text("No se pudieron cargar tus pagos", bundle: .module)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                }
            } description: {
                Text(verbatim: error.message)
            } actions: {
                Button {
                    viewModel.load()
                } label: {
                    Text("Reintentar", bundle: .module)
                }
            }
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
                HStack {
                    VStack(alignment: .leading) {
                        Text(total.fortnight.title)
                        Text(total.fortnight.daysDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    MoneyText(total.total)
                }
                .accessibilityElement(children: .combine)
            }
        } header: {
            Text("Análisis quincenal", bundle: .module)
        }
    }

    private func row(_ item: MonthStatement.Item) -> some View {
        Button {
            onSelectPayment(item.id)
        } label: {
            PaymentRow(item: item)
        }
        .foregroundStyle(.primary)
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

struct PaymentRow: View {
    let item: MonthStatement.Item

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.name)
                CategoryBadge(item.category)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                MoneyText(item.displayAmount)
                Text("Día \(item.effectiveDay)", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
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
