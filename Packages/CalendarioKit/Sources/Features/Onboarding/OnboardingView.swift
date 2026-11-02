import DesignSystem
import Domain
import SwiftUI

public struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel

    public init(viewModel: OnboardingViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Button {
                            viewModel.selectedCurrency = currency
                        } label: {
                            HStack {
                                Text(currency.displayName)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.selectedCurrency == currency {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(viewModel.selectedCurrency == currency ? .isSelected : [])
                    }
                } header: {
                    Text("Moneda", bundle: .module)
                } footer: {
                    Text(
                        "Todos los montos de la app se mostrarán en esta moneda. La app trabaja con una sola moneda y no hace conversiones.",
                        bundle: .module)
                }
            }
            .navigationTitle(Text("Elige tu moneda", bundle: .module))
            .safeAreaInset(edge: .bottom) {
                Button {
                    viewModel.complete()
                } label: {
                    Text("Continuar", bundle: .module)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canContinue)
                .padding()
            }
            .alert(
                Text("No se pudo guardar", bundle: .module),
                isPresented: Binding(get: { viewModel.error != nil }, set: { if !$0 { viewModel.dismissError() } }),
                presenting: viewModel.error
            ) { _ in
            } message: { error in
                Text(verbatim: error.message)
            }
        }
    }
}

extension Currency {
    var displayName: LocalizedStringResource {
        switch self {
        case .usd: LocalizedStringResource("Dólar estadounidense ($)", bundle: .features)
        case .eur: LocalizedStringResource("Euro (€)", bundle: .features)
        }
    }
}

extension LocalizedStringResource.BundleDescription {
    /// Catálogo de cadenas del módulo `Features`.
    static let features: Self = .atURL(Bundle.module.bundleURL)
}
