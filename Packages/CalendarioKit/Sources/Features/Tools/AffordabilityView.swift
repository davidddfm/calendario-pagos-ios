import DesignSystem
import Domain
import SwiftUI

/// ¿Puedo costearlo? (HER-01 a HER-03).
public struct AffordabilityView: View {
    @State private var viewModel: AffordabilityViewModel
    @Environment(DataChangeTracker.self) private var changes
    @Environment(\.currency) private var currency
    private let onConfigureSalary: () -> Void

    public init(viewModel: AffordabilityViewModel, onConfigureSalary: @escaping () -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onConfigureSalary = onConfigureSalary
    }

    public var body: some View {
        Form {
            if case .loaded = viewModel.state {
                if viewModel.hasSalary {
                    inputSection
                    if let result = viewModel.result {
                        resultSections(result)
                    }
                } else {
                    // S-05
                    SalaryRequiredCard(
                        message: Text(
                            "Con tu salario neto mensual calculamos si un nuevo gasto cabe en tu plan 50/30/20.",
                            bundle: .module),
                        onConfigure: onConfigureSalary)
                }
            }
        }
        .navigationTitle(Text("¿Puedo costearlo?", bundle: .module))
        .overlay { LoadStateOverlay(state: viewModel.state, retry: viewModel.load) }
        .task(id: changes.version) { viewModel.load() }
    }

    private var inputSection: some View {
        Section {
            HStack {
                Text(verbatim: MoneyFormatter.symbol(for: currency))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField(text: $viewModel.amountText) {
                    Text("Monto mensual del nuevo gasto", bundle: .module)
                }
                .keyboardType(.decimalPad)
                .accessibilityIdentifier("affordability.amount")
            }
            Picker(selection: $viewModel.kind) {
                Text("Necesidad", bundle: .module).tag(ExpenseKind.need)
                Text("Deseo", bundle: .module).tag(ExpenseKind.want)
            } label: {
                Text("Tipo de gasto", bundle: .module)
            }
            .pickerStyle(.segmented)
        } header: {
            Text("Nuevo gasto", bundle: .module)
        } footer: {
            Text("Herramienta informativa; no constituye asesoría financiera.", bundle: .module)
        }
    }

    @ViewBuilder
    private func resultSections(_ result: AffordabilityResult) -> some View {
        Section {
            TrafficLightView(result.light, message: message(for: result))
        }
        Section {
            BucketRow(
                title: Text("Necesidades", bundle: .module), amount: result.needs, share: result.needsShare, ideal: 0.5)
            BucketRow(
                title: Text("Deseos", bundle: .module), amount: result.wants, share: result.wantsShare, ideal: 0.3)
            BucketRow(
                title: Text("Ahorro", bundle: .module), amount: result.savings, share: result.savingsShare, ideal: 0.2)
        } header: {
            Text("Tu distribución con este gasto", bundle: .module)
        }
    }

    private func message(for result: AffordabilityResult) -> Text {
        let savings = result.savingsShare.formatted(.percent.precision(.fractionLength(0)))
        if let newExpense = viewModel.newExpense, newExpense > result.salary {
            return Text("El gasto supera tu salario.", bundle: .module)
        }
        return switch result.light {
        case .green: Text("Tu ahorro quedaría en \(savings) del salario: 15% o más.", bundle: .module)
        case .yellow: Text("Tu ahorro quedaría en \(savings) del salario: entre 10% y 15%.", bundle: .module)
        case .red: Text("Tu ahorro quedaría en \(savings) del salario: menos del 10%.", bundle: .module)
        }
    }
}

/// HER-02: monto y porcentaje frente a la regla 50/30/20.
private struct BucketRow: View {
    let title: Text
    let amount: Money
    let share: Double
    let ideal: Double

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                title
                Text(
                    "\(share.formatted(.percent.precision(.fractionLength(0)))) · ideal \(ideal.formatted(.percent.precision(.fractionLength(0))))",
                    bundle: .module
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            MoneyText(amount)
                .foregroundStyle(amount.isNegative ? Color.red : Color.primary)
        }
        .accessibilityElement(children: .combine)
    }
}
