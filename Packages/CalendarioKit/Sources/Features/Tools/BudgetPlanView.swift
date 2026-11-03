import DesignSystem
import Domain
import SwiftUI

/// Plan 50/30/20, solo informativo (HER-07).
public struct BudgetPlanView: View {
    @State private var viewModel: BudgetPlanViewModel
    @Environment(DataChangeTracker.self) private var changes
    private let onConfigureSalary: () -> Void

    public init(viewModel: BudgetPlanViewModel, onConfigureSalary: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onConfigureSalary = onConfigureSalary
    }

    public var body: some View {
        List {
            if case .loaded(let plan) = viewModel.state {
                if let plan {
                    Section {
                        PlanRow(title: Text("Necesidades", bundle: .module), percent: 50, amount: plan.needs)
                        PlanRow(title: Text("Deseos", bundle: .module), percent: 30, amount: plan.wants)
                        PlanRow(title: Text("Ahorro", bundle: .module), percent: 20, amount: plan.savings)
                    } header: {
                        Text("Cómo repartir tu salario", bundle: .module)
                    } footer: {
                        Text(
                            "Necesidades: servicios, transportes, préstamos y gastos. Deseos: bienestar. Ahorro: ahorros e inversiones. Herramienta informativa; no constituye asesoría financiera.",
                            bundle: .module)
                    }
                } else {
                    // S-05
                    SalaryRequiredCard(
                        message: Text(
                            "Con tu salario neto mensual calculamos cuánto destinar a necesidades, deseos y ahorro.",
                            bundle: .module),
                        onConfigure: onConfigureSalary)
                }
            }
        }
        .navigationTitle(Text("Plan 50/30/20", bundle: .module))
        .overlay { LoadStateOverlay(state: viewModel.state, retry: viewModel.load) }
        .task(id: changes.version) { viewModel.load() }
    }
}

private struct PlanRow: View {
    let title: Text
    let percent: Int
    let amount: Money

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                title
                Text("\((Double(percent) / 100).formatted(.percent)) del salario", bundle: .module)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            MoneyText(amount)
        }
        .accessibilityElement(children: .combine)
    }
}
