import Charts
import DesignSystem
import Domain
import SwiftUI

/// Historial mensual: gráfica de 6 meses y lista de meses (HIS-01, HIS-02).
public struct HistoryView: View {
    @State private var viewModel: HistoryViewModel
    @Environment(DataChangeTracker.self) private var changes
    @Environment(\.currency) private var currency
    private let onOpenMonth: (YearMonth) -> Void

    public init(viewModel: HistoryViewModel, onOpenMonth: @escaping (YearMonth) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenMonth = onOpenMonth
    }

    public var body: some View {
        content
            .navigationTitle(Text("Historial de pagos", bundle: .module))
            .task(id: changes.version) { viewModel.load() }
    }

    /// Siempre la misma `List`: cambiar de contenedor tras la carga deja el contenido bajo el título grande.
    private var content: some View {
        List {
            if let overview = viewModel.state.value, !overview.isEmpty {
                Section {
                    chart(overview.chart)
                        .frame(height: 180)
                        .padding(.vertical, 8)
                } header: {
                    Text("Total pagado, últimos 6 meses", bundle: .module)
                }

                Section {
                    ForEach(overview.months) { month in
                        Button {
                            onOpenMonth(month.period)
                        } label: {
                            MonthRow(month: month)
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("Meses", bundle: .module)
                }
            }
        }
        .overlay {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()
            case .failed(let error):
                LoadFailedView(error: error, retry: viewModel.load)
            case .loaded(let overview) where overview.isEmpty:
                ContentUnavailableView {
                    Label {
                        Text("Aún no hay historial", bundle: .module)
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                } description: {
                    Text("Cuando registres pagos, aquí verás cuánto pagaste cada mes.", bundle: .module)
                }
            case .loaded:
                EmptyView()
            }
        }
    }

    /// HIS-02
    private func chart(_ months: [HistoryOverview.MonthSummary]) -> some View {
        Chart(months) { month in
            BarMark(
                x: .value(Text("Mes", bundle: .module), month.startDate, unit: .month),
                y: .value(Text("Total pagado", bundle: .module), month.paidTotal.decimal)
            )
            .foregroundStyle(Color.accentColor)
            .accessibilityLabel(Text(month.startDate, format: .dateTime.month(.wide).year()))
            .accessibilityValue(Text(verbatim: MoneyFormatter.string(month.paidTotal, currency: currency)))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .month)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Decimal.self) {
                        Text(verbatim: amount.formatted(.number.notation(.compactName)))
                    }
                }
            }
        }
    }
}

/// HIS-01: total pagado, pagos cumplidos y porcentaje.
private struct MonthRow: View {
    let month: HistoryOverview.MonthSummary

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(month.startDate, format: .dateTime.month(.wide).year())
                    .textCase(nil)
                Text(
                    "\(month.paidCount) de \(month.totalCount) pagos · \(month.compliance.formatted(.percent.precision(.fractionLength(0))))",
                    bundle: .module
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            MoneyText(month.paidTotal)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
