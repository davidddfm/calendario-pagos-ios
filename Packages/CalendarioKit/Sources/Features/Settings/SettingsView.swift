import DesignSystem
import Domain
import SwiftUI

/// Ajustes: salario y moneda (CFG-01, DAS-05, MND-03).
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.currency) private var currency
    @FocusState private var isSalaryFocused: Bool

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            salarySection
            currencySection
        }
        .navigationTitle(Text("Configuración", bundle: .module))
        .onAppear(perform: viewModel.load)
        .alert(
            Text("¿Cambiar la moneda?", bundle: .module),
            isPresented: Binding(
                get: { viewModel.pendingCurrency != nil },
                set: { if !$0 { viewModel.cancelCurrencyChange() } }),
            presenting: viewModel.pendingCurrency
        ) { newCurrency in
            Button {
                viewModel.confirmCurrencyChange()
            } label: {
                Text("Cambiar a \(Text(newCurrency.displayName))", bundle: .module)
            }
            Button(role: .cancel) {
                viewModel.cancelCurrencyChange()
            } label: {
                Text("Cancelar", bundle: .module)
            }
        } message: { _ in
            Text("Los montos no se convertirán, solo cambiará el símbolo.", bundle: .module)
        }
        .actionErrorAlert(error: viewModel.actionError, dismiss: viewModel.dismissActionError)
    }

    private var salarySection: some View {
        Section {
            HStack {
                Text(verbatim: MoneyFormatter.symbol(for: currency))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField(text: $viewModel.salaryText) {
                    Text("Salario neto mensual", bundle: .module)
                }
                .keyboardType(.decimalPad)
                .focused($isSalaryFocused)
                .accessibilityIdentifier("settings.salary")
            }
            if let error = viewModel.salaryError {
                Text(verbatim: error.errorDescription ?? "")
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button {
                isSalaryFocused = false
                viewModel.saveSalary()
            } label: {
                Text("Guardar salario", bundle: .module)
            }
            .disabled(!viewModel.canSaveSalary)
            if viewModel.savedSalary != nil {
                Button(role: .destructive) {
                    isSalaryFocused = false
                    viewModel.removeSalary()
                } label: {
                    Text("Quitar salario", bundle: .module)
                }
            }
        } header: {
            Text("Salario", bundle: .module)
        } footer: {
            Text(
                "Tu salario neto mensual, hasta 9,999,999. Es la base del Dashboard, las quincenas y las herramientas.",
                bundle: .module)
        }
    }

    private var currencySection: some View {
        Section {
            Picker(
                selection: Binding(
                    get: { viewModel.currency ?? currency },
                    set: { viewModel.requestCurrencyChange(to: $0) })
            ) {
                ForEach(Currency.allCases, id: \.self) { option in
                    Text(option.displayName).tag(option)
                }
            } label: {
                Text("Moneda", bundle: .module)
            }
            .accessibilityIdentifier("settings.currency")
        } header: {
            Text("Moneda", bundle: .module)
        } footer: {
            Text("La app trabaja con una sola moneda. Al cambiarla, los montos no se convierten.", bundle: .module)
        }
    }
}
