import SwiftUI

/// DAS-04 / QUI-04: invitación a configurar el salario en lugar de los cálculos que lo necesitan.
public struct SalaryRequiredCard: View {
    private let message: Text
    private let onConfigure: (() -> Void)?

    /// - Parameter onConfigure: acceso directo a Ajustes; sin él solo se muestra la invitación.
    public init(message: Text, onConfigure: (() -> Void)? = nil) {
        self.message = message
        self.onConfigure = onConfigure
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label {
                Text("Configura tu salario", bundle: .module)
                    .font(.headline)
            } icon: {
                Image(systemName: "banknote")
            }
            message
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let onConfigure {
                Button(action: onConfigure) {
                    Text("Ir a Ajustes", bundle: .module)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}
