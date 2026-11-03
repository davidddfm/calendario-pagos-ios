import Charts
import DesignSystem
import Domain
import SwiftUI

/// Pestaña Perfil: disponible del mes, gastos por categoría y fondo de emergencia (DAS-01 a DAS-06).
public struct DashboardView: View {
    @State private var viewModel: DashboardViewModel
    @Environment(DataChangeTracker.self) private var changes
    private let onConfigureSalary: () -> Void
    private let onOpenHistory: () -> Void

    public init(
        viewModel: DashboardViewModel,
        onConfigureSalary: @escaping () -> Void,
        onOpenHistory: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onConfigureSalary = onConfigureSalary
        self.onOpenHistory = onOpenHistory
    }

    public var body: some View {
        content
            .navigationTitle(Text("Perfil", bundle: .module))
            .task(id: changes.version) { viewModel.load() }
    }

    /// Siempre la misma `List` (ver `HistoryView`); cada sección es una tarjeta.
    private var content: some View {
        List {
            if let summary = viewModel.state.value {
                availabilitySection(summary)
                categoriesSection(summary)
                emergencyFundSection(summary.emergencyFund)
                Section {
                    // DAS-06
                    Button(action: onOpenHistory) {
                        Label {
                            Text("Ver historial", bundle: .module)
                        } icon: {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                    }
                }
            }
        }
        .overlay { LoadStateOverlay(state: viewModel.state, retry: viewModel.load) }
    }

    @ViewBuilder
    private func availabilitySection(_ summary: DashboardSummary) -> some View {
        Section {
            if let availability = summary.availability {
                VStack(alignment: .leading, spacing: 8) {
                    // DAS-02: en negativo, en rojo y con signo.
                    MoneyText(availability.available)
                        .font(.largeTitle.bold())
                        .foregroundStyle(availability.isOverdrawn ? Color.red : Color.primary)
                    if availability.isOverdrawn {
                        Label {
                            Text("Tus pagos superan tu salario.", bundle: .module)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                    }
                    // DAS-01: verde hasta el 50 %, naranja por encima.
                    ProgressBar(
                        value: availability.spentRatio,
                        tint: availability.level == .healthy ? .green : .orange,
                        label: Text(
                            "\(availability.spentRatio.formatted(.percent.precision(.fractionLength(0)))) del salario en pagos",
                            bundle: .module))
                }
                .accessibilityElement(children: .combine)
                .padding(.vertical, 4)
                LabeledAmount(Text("Salario neto", bundle: .module), availability.salary)
                LabeledAmount(Text("Total de pagos", bundle: .module), summary.totalMonthly)
            } else {
                // DAS-04
                SalaryRequiredCard(
                    message: Text(
                        "Con tu salario neto mensual calculamos cuánto te queda disponible cada mes.", bundle: .module),
                    onConfigure: onConfigureSalary)
                LabeledAmount(Text("Total de pagos", bundle: .module), summary.totalMonthly)
            }
        } header: {
            Text("Disponible este mes", bundle: .module)
        }
    }

    @ViewBuilder
    private func categoriesSection(_ summary: DashboardSummary) -> some View {
        Section {
            if summary.categoryShares.isEmpty {
                Text("Cuando registres pagos, aquí verás en qué se va tu dinero.", bundle: .module)
                    .foregroundStyle(.secondary)
            } else {
                CategoryChart(shares: summary.categoryShares)
                    .frame(height: 200)
                    .padding(.vertical, 8)
                ForEach(summary.categoryShares, id: \.category) { share in
                    HStack {
                        CategoryBadge(share.category)
                        Spacer()
                        Text(share.share, format: .percent.precision(.fractionLength(0)))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        MoneyText(share.total)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        } header: {
            Text("Gastos por categoría", bundle: .module)
        }
    }

    private func emergencyFundSection(_ fund: DashboardSummary.EmergencyFund) -> some View {
        Section {
            LabeledAmount(Text("3 meses", bundle: .module), fund.threeMonths)
            LabeledAmount(Text("6 meses", bundle: .module), fund.sixMonths)
            LabeledAmount(Text("12 meses", bundle: .module), fund.twelveMonths)
        } header: {
            Text("Tu fondo de emergencia", bundle: .module)
        } footer: {
            Text("Lo que necesitarías ahorrado para cubrir tus pagos mensuales.", bundle: .module)
        }
    }
}

/// DAS-03: solo categorías con pagos.
private struct CategoryChart: View {
    let shares: [DashboardSummary.CategoryShare]

    var body: some View {
        Chart(shares, id: \.category) { share in
            SectorMark(angle: .value(Text("Total", bundle: .module), share.share), innerRadius: .ratio(0.6))
                .foregroundStyle(
                    by: .value(Text("Categoría", bundle: .module), String(localized: share.category.localizedName))
                )
                .accessibilityLabel(Text(share.category.localizedName))
                .accessibilityValue(Text(share.share, format: .percent.precision(.fractionLength(0))))
        }
    }
}

/// Fila de texto y monto.
struct LabeledAmount: View {
    private let title: Text
    private let amount: Money

    init(_ title: Text, _ amount: Money) {
        self.title = title
        self.amount = amount
    }

    var body: some View {
        HStack {
            title
            Spacer()
            MoneyText(amount)
        }
        .accessibilityElement(children: .combine)
    }
}
