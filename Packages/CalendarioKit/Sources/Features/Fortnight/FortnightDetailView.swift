import DesignSystem
import Domain
import SwiftUI

/// Detalle de una quincena del mes actual (QUI-01 a QUI-04).
public struct FortnightDetailView: View {
    @State private var viewModel: FortnightViewModel
    @Environment(DataChangeTracker.self) private var changes
    private let onSelectPayment: (UUID) -> Void
    private let onConfigureSalary: () -> Void

    public init(
        viewModel: FortnightViewModel,
        onSelectPayment: @escaping (UUID) -> Void,
        onConfigureSalary: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectPayment = onSelectPayment
        self.onConfigureSalary = onConfigureSalary
    }

    public var body: some View {
        content
            .navigationTitle(Text(viewModel.fortnight.title))
            .task(id: changes.version) { viewModel.load() }
            .actionErrorAlert(error: viewModel.actionError, dismiss: viewModel.dismissActionError)
    }

    /// Siempre la misma `List` (ver `HistoryView`).
    private var content: some View {
        List {
            if let detail = viewModel.state.value {
                Section {
                    if let remaining = detail.remaining {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Saldo restante (aproximado)", bundle: .module)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            MoneyText(remaining)
                                .font(.largeTitle.bold())
                                .foregroundStyle(remaining.isNegative ? Color.red : Color.primary)
                            Text("La mitad de tu salario menos los pagos de esta quincena.", bundle: .module)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    } else {
                        // QUI-04
                        SalaryRequiredCard(
                            message: Text(
                                "Con tu salario neto mensual calculamos cuánto te queda en cada quincena.",
                                bundle: .module),
                            onConfigure: onConfigureSalary)
                    }
                    HStack {
                        Text("Total de pagos", bundle: .module)
                        Spacer()
                        MoneyText(detail.total)
                    }
                    .accessibilityElement(children: .combine)
                }

                Section {
                    if detail.items.isEmpty {
                        Text("No hay pagos en esta quincena.", bundle: .module)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(detail.items) { item in
                            PaymentRow(
                                item: item,
                                onTogglePaid: { viewModel.togglePaid(item) },
                                onSelect: { onSelectPayment(item.id) })
                        }
                    }
                } header: {
                    Text(viewModel.fortnight.daysDescription)
                }
            }
        }
        .overlay { LoadStateOverlay(state: viewModel.state, retry: viewModel.load) }
    }
}
