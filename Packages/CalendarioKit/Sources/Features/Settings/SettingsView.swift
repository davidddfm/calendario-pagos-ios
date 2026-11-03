import DesignSystem
import Domain
import SwiftUI
import UIKit

/// Ajustes: salario, moneda, recordatorios y seguridad (CFG-01, DAS-05, MND-03, NOT-02, NOT-05, NOT-06, SEG-01, SEG-02).
public struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    @Environment(\.currency) private var currency
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @FocusState private var isSalaryFocused: Bool

    public init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        Form {
            salarySection
            currencySection
            remindersSection
            securitySection
        }
        .navigationTitle(Text("Configuración", bundle: .module))
        .onAppear(perform: viewModel.load)
        // NOT-06: el permiso puede cambiar en los ajustes del iPhone mientras la app está en segundo plano.
        .task(id: scenePhase) {
            if scenePhase == .active { await viewModel.refreshReminderAuthorization() }
        }
        .alert(
            Text("Configura un código en tu iPhone", bundle: .module),
            isPresented: Binding(
                get: { viewModel.showsPasscodeRequiredAlert },
                set: { if !$0 { viewModel.dismissPasscodeRequiredAlert() } })
        ) {
        } message: {
            Text("Para bloquear la app, tu iPhone necesita un código de desbloqueo.", bundle: .module)
        }
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

    private var remindersSection: some View {
        Section {
            Toggle(
                isOn: Binding(
                    get: { viewModel.reminders.isEnabled },
                    set: { isEnabled in Task { await viewModel.setRemindersEnabled(isEnabled) } })
            ) {
                Text("Recordatorios", bundle: .module)
            }
            .accessibilityIdentifier("settings.reminders")
            if viewModel.reminders.isEnabled {
                DatePicker(
                    selection: Binding(get: { viewModel.reminderTime }, set: { viewModel.setReminderTime($0) }),
                    displayedComponents: .hourAndMinute
                ) {
                    Text("Hora del aviso", bundle: .module)
                }
                switch viewModel.reminderAuthorization {
                case .denied:
                    // NOT-06
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Notificaciones bloqueadas", bundle: .module)
                        } icon: {
                            Image(systemName: "bell.slash")
                        }
                        .foregroundStyle(.orange)
                        Button {
                            if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                        } label: {
                            Text("Activarlas en los ajustes del iPhone", bundle: .module)
                        }
                    }
                case .notDetermined:
                    Button {
                        Task { await viewModel.requestPermission() }
                    } label: {
                        Text("Permitir notificaciones", bundle: .module)
                    }
                case .authorized, nil:
                    EmptyView()
                }
            }
        } header: {
            Text("Recordatorios", bundle: .module)
        } footer: {
            Text(
                "Un aviso al día, solo los días con pagos pendientes. Muestra los nombres de los pagos, nunca montos.",
                bundle: .module)
        }
    }

    private var securitySection: some View {
        Section {
            Toggle(
                isOn: Binding(
                    get: { viewModel.appLock.isEnabled },
                    set: { isEnabled in Task { await viewModel.setLockEnabled(isEnabled) } })
            ) {
                lockTitle
            }
            .accessibilityIdentifier("settings.appLock")
            if viewModel.appLock.isEnabled {
                Picker(
                    selection: Binding(get: { viewModel.appLock.gracePeriod }, set: { viewModel.setGracePeriod($0) })
                ) {
                    ForEach(LockGracePeriod.allCases, id: \.self) { period in
                        Text(period.title).tag(period)
                    }
                } label: {
                    Text("Pedirlo de nuevo", bundle: .module)
                }
                .accessibilityIdentifier("settings.gracePeriod")
            }
        } header: {
            Text("Seguridad", bundle: .module)
        } footer: {
            Text("Al abrir la app y al volver a ella tras el tiempo elegido.", bundle: .module)
        }
    }

    /// §11.9: nombra el método disponible en el iPhone.
    private var lockTitle: Text {
        switch viewModel.biometry {
        case .faceID: Text("Bloquear con Face ID", bundle: .module)
        case .touchID: Text("Bloquear con Touch ID", bundle: .module)
        case .none: Text("Bloquear con el código del iPhone", bundle: .module)
        }
    }
}

extension LockGracePeriod {
    /// SEG-02
    var title: LocalizedStringResource {
        switch self {
        case .immediately: LocalizedStringResource("Inmediatamente", bundle: .features)
        case .oneMinute: LocalizedStringResource("Después de 1 minuto", bundle: .features)
        case .fiveMinutes: LocalizedStringResource("Después de 5 minutos", bundle: .features)
        case .fifteenMinutes: LocalizedStringResource("Después de 15 minutos", bundle: .features)
        }
    }
}
