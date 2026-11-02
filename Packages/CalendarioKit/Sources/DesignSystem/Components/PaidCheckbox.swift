import SwiftUI

/// MAR-01: único control de "pagado" de la app. El estado se comunica con icono y etiqueta, no solo con color.
public struct PaidCheckbox: View {
    private let isPaid: Bool
    private let paymentName: String
    private let action: () -> Void

    public init(isPaid: Bool, paymentName: String, action: @escaping () -> Void) {
        self.isPaid = isPaid
        self.paymentName = paymentName
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: isPaid ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundStyle(isPaid ? Color.green : Color.secondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .sensoryFeedback(.success, trigger: isPaid) { _, paid in paid }
        .accessibilityLabel(
            isPaid
                ? Text("Marcar \(paymentName) como pendiente", bundle: .module)
                : Text("Marcar \(paymentName) como pagado", bundle: .module)
        )
        .accessibilityValue(isPaid ? Text("Pagado", bundle: .module) : Text("Pendiente", bundle: .module))
        .accessibilityIdentifier("paid.\(paymentName)")
    }
}

#if DEBUG
    #Preview {
        @Previewable @State var isPaid = false
        PaidCheckbox(isPaid: isPaid, paymentName: "Renta") { isPaid.toggle() }
    }
#endif
