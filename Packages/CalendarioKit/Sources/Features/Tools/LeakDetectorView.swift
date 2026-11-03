import DesignSystem
import Domain
import SwiftUI

/// Detector de fugas: costo anual de cada pago (HER-04 a HER-06).
public struct LeakDetectorView: View {
    @State private var viewModel: LeakDetectorViewModel
    @Environment(DataChangeTracker.self) private var changes

    public init(viewModel: LeakDetectorViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        List {
            if let report = viewModel.state.value, !report.items.isEmpty {
                Section {
                    ForEach(report.items) { LeakRow(item: $0) }
                } header: {
                    Text("Costo anual de cada pago", bundle: .module)
                } footer: {
                    Text("Cada pago se cuenta como un gasto mensual recurrente.", bundle: .module)
                }

                Section {
                    // HER-05
                    LabeledAmount(Text("Total anual", bundle: .module), report.annualTotal)
                        .font(.headline)
                }
            }
        }
        .navigationTitle(Text("Detector de fugas", bundle: .module))
        .overlay {
            if case .loaded(let report) = viewModel.state, report.items.isEmpty {
                ContentUnavailableView {
                    Label {
                        Text("Sin pagos registrados", bundle: .module)
                    } icon: {
                        Image(systemName: "drop")
                    }
                } description: {
                    Text("Cuando registres pagos, aquí verás cuánto te cuesta cada uno al año.", bundle: .module)
                }
            } else {
                LoadStateOverlay(state: viewModel.state, retry: viewModel.load)
            }
        }
        .task(id: changes.version) { viewModel.load() }
    }
}

/// HER-04: costo anual y monto mensual de un pago.
private struct LeakRow: View {
    let item: LeakReport.Item
    @Environment(\.currency) private var currency

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.name)
                CategoryBadge(item.category)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                MoneyText(item.annualCost)
                Text(
                    "\(Text(verbatim: MoneyFormatter.string(item.monthlyAmount, currency: currency))) al mes",
                    bundle: .module
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
