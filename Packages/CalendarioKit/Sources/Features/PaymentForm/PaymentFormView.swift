import DesignSystem
import Domain
import SwiftUI

/// Hoja para crear o editar un pago (NAV-01: abrir es el toque 1, guardar el toque 2).
public struct PaymentFormView: View {
    @State private var viewModel: PaymentFormViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.currency) private var currency
    @FocusState private var focusedField: Field?

    private enum Field { case name, amount }

    public init(viewModel: PaymentFormViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            if let loadError = viewModel.loadError {
                Text(verbatim: loadError.message)
                    .foregroundStyle(.red)
            } else {
                fields
                if viewModel.isEditing {
                    Section {
                        Button(role: .destructive) {
                            viewModel.isConfirmingDeletion = true
                        } label: {
                            Text("Eliminar pago", bundle: .module)
                        }
                    }
                }
            }
        }
        .navigationTitle(
            viewModel.isEditing ? Text("Editar pago", bundle: .module) : Text("Nuevo pago", bundle: .module)
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text("Cancelar", bundle: .module)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    viewModel.save()
                } label: {
                    Text("Guardar", bundle: .module)
                }
                .disabled(!viewModel.canSave)
            }
        }
        .onAppear {
            viewModel.load()
            if !viewModel.isEditing { focusedField = .name }
        }
        .task { await viewModel.prepareReminderPermission() }
        // NOT-06 / S-08: dos botones de igual peso; ninguno imita el diálogo del sistema.
        .alert(
            Text("¿Quieres que te recordemos tus pagos?", bundle: .module),
            isPresented: Binding(get: { viewModel.showsReminderPrompt }, set: { _ in })
        ) {
            Button {
                Task { await viewModel.respondToReminderPrompt(accepted: true) }
            } label: {
                Text("Activar recordatorios", bundle: .module)
            }
            Button {
                Task { await viewModel.respondToReminderPrompt(accepted: false) }
            } label: {
                Text("Ahora no", bundle: .module)
            }
        } message: {
            Text(
                "Te avisamos una vez al día, solo los días con pagos, con sus nombres y nunca con montos. Puedes cambiarlo en Configuración.",
                bundle: .module)
        }
        .onChange(of: viewModel.didFinish) { _, finished in
            if finished { dismiss() }
        }
        .confirmationDialog(
            Text("¿Eliminar este pago?", bundle: .module),
            isPresented: $viewModel.isConfirmingDeletion,
            titleVisibility: .visible
        ) {
            Button(role: .destructive) {
                viewModel.confirmDeletion()
            } label: {
                Text("Eliminar pago", bundle: .module)
            }
        } message: {
            Text("Dejará de aparecer desde este mes. Los meses anteriores conservan su registro.", bundle: .module)
        }
        .alert(
            Text("No se pudo guardar", bundle: .module),
            isPresented: Binding(
                get: { viewModel.actionError != nil }, set: { if !$0 { viewModel.dismissActionError() } }),
            presenting: viewModel.actionError
        ) { _ in
        } message: { error in
            Text(verbatim: error.message)
        }
    }

    @ViewBuilder
    private var fields: some View {
        Section {
            TextField(text: $viewModel.name) {
                Text("Nombre", bundle: .module)
            }
            .focused($focusedField, equals: .name)
            .submitLabel(.next)
            .onSubmit { focusedField = .amount }
            .accessibilityIdentifier("payment.name")
            if let error = viewModel.nameError {
                FieldError(error)
            }
        }

        Section {
            HStack {
                Text(verbatim: MoneyFormatter.symbol(for: currency))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField(text: $viewModel.amountText) {
                    Text("Monto", bundle: .module)
                }
                .keyboardType(.decimalPad)
                .focused($focusedField, equals: .amount)
                .accessibilityIdentifier("payment.amount")
            }
            if let error = viewModel.amountError {
                FieldError(error)
            }
        }

        Section {
            Picker(selection: $viewModel.dayOfMonth) {
                ForEach(PaymentValidator.validDays, id: \.self) { day in
                    Text(verbatim: "\(day)").tag(day)
                }
            } label: {
                Text("Día del mes", bundle: .module)
            }
            .accessibilityIdentifier("payment.day")
            Picker(selection: $viewModel.category) {
                ForEach(PaymentCategory.allCases, id: \.self) { category in
                    Label {
                        Text(category.localizedName)
                    } icon: {
                        Image(systemName: category.symbolName)
                    }
                    .tag(category)
                }
            } label: {
                Text("Categoría", bundle: .module)
            }
        } footer: {
            // PAG-03 y PAG-07, informativos.
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.fortnight.title)
                if viewModel.dayOfMonth > 28 {
                    Text("En los meses sin este día, el pago se muestra el último día del mes.", bundle: .module)
                }
            }
        }
    }
}

private struct FieldError: View {
    let error: PaymentValidationError

    init(_ error: PaymentValidationError) {
        self.error = error
    }

    var body: some View {
        Text(verbatim: error.errorDescription ?? "")
            .font(.footnote)
            .foregroundStyle(.red)
    }
}
