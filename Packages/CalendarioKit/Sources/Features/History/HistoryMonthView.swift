import DesignSystem
import Domain
import SwiftUI

/// Pagos de un mes separados en pagados y pendientes (HIS-03), con casillas para corregir (HIS-04).
public struct HistoryMonthView: View {
    @State private var viewModel: HistoryMonthViewModel
    @Environment(DataChangeTracker.self) private var changes

    public init(viewModel: HistoryMonthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        content
            .navigationTitle(title)
            .task(id: changes.version) { viewModel.load() }
            .actionErrorAlert(error: viewModel.actionError, dismiss: viewModel.dismissActionError)
    }

    private var title: Text {
        if let startDate = viewModel.startDate {
            Text(startDate, format: .dateTime.month(.wide).year())
        } else {
            Text("Historial de pagos", bundle: .module)
        }
    }

    /// Siempre la misma `List` (ver `HistoryView`).
    private var content: some View {
        List {
            if let statement = viewModel.state.value {
                Section {
                    HStack {
                        Text("Total pagado", bundle: .module)
                        Spacer()
                        MoneyText(statement.paidTotal)
                    }
                    .accessibilityElement(children: .combine)
                }
                section(
                    statement.paid, title: Text("Pagados", bundle: .module),
                    empty: Text("Ningún pago marcado.", bundle: .module))
                section(
                    statement.pending, title: Text("Pendientes", bundle: .module),
                    empty: Text("Todo pagado.", bundle: .module))
            }
        }
    }

    private func section(_ items: [MonthStatement.Item], title: Text, empty: Text) -> some View {
        Section {
            if items.isEmpty {
                empty.foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    PaymentRow(item: item, onTogglePaid: { viewModel.togglePaid(item) })
                }
            }
        } header: {
            title
        }
    }
}
