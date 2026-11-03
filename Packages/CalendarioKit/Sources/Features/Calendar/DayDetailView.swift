import DesignSystem
import Domain
import SwiftUI

/// Detalle de un día del Calendario (CAL-03 a CAL-06).
public struct DayDetailView: View {
    @State private var viewModel: DayDetailViewModel
    @Environment(DataChangeTracker.self) private var changes
    private let onSelectPayment: (UUID) -> Void

    public init(viewModel: DayDetailViewModel, onSelectPayment: @escaping (UUID) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectPayment = onSelectPayment
    }

    public var body: some View {
        content
            .navigationTitle(Text(viewModel.date, format: .dateTime.day().month(.wide)))
            .navigationBarTitleDisplayMode(.inline)
            .task(id: changes.version) { viewModel.load() }
            .actionErrorAlert(error: viewModel.actionError, dismiss: viewModel.dismissActionError)
    }

    /// Siempre la misma `List` (ver `HistoryView`).
    private var content: some View {
        List {
            if let detail = viewModel.state.value {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        // CAL-03: fecha completa y total del día.
                        Text(detail.date, format: .dateTime.weekday(.wide).day().month(.wide).year())
                            .font(.headline)
                        MoneyText(detail.total)
                            .font(.largeTitle.bold())
                        if detail.isEditable, !detail.items.isEmpty {
                            // CAL-04
                            ProgressBar(
                                value: detail.progress,
                                tint: .green,
                                label: Text("\(detail.paidCount) de \(detail.items.count) pagados", bundle: .module))
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .padding(.vertical, 4)
                }

                Section {
                    if detail.items.isEmpty {
                        Text("No hay pagos este día.", bundle: .module)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(detail.items) { item in
                            PaymentRow(
                                item: item,
                                // CAL-05: sin casillas fuera del mes actual.
                                onTogglePaid: detail.isEditable ? { viewModel.togglePaid(item) } : nil,
                                // CAL-06: solo un pago vigente se puede editar.
                                onSelect: item.paymentExists ? { onSelectPayment(item.id) } : nil)
                        }
                    }
                } header: {
                    Text("Pagos", bundle: .module)
                } footer: {
                    if !detail.isEditable, !detail.items.isEmpty {
                        Text("Para corregir lo pagado en otros meses, usa el Historial.", bundle: .module)
                    }
                }
            }
        }
        .overlay { LoadStateOverlay(state: viewModel.state, retry: viewModel.load) }
    }
}
