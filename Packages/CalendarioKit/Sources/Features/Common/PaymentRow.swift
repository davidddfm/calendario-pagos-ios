import DesignSystem
import Domain
import SwiftUI

/// Fila de pago común a Inicio, Quincena e Historial.
struct PaymentRow: View {
    let item: MonthStatement.Item
    /// MAR-02: `nil` oculta la casilla.
    var onTogglePaid: (() -> Void)?
    /// `nil` = la fila no abre la edición (p. ej. un pago eliminado en el Historial).
    var onSelect: (() -> Void)?

    var body: some View {
        HStack(spacing: 8) {
            if let onTogglePaid {
                PaidCheckbox(isPaid: item.isPaid, paymentName: item.name, action: onTogglePaid)
            }
            if let onSelect {
                Button(action: onSelect) { content }
                    .buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: item.name)
                CategoryBadge(item.category)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                MoneyText(item.paidAmountDiffers ? (item.currentAmount ?? item.displayAmount) : item.displayAmount)
                if item.paidAmountDiffers {
                    // MAR-05: se pagó con un monto distinto al actual.
                    Text("Pagado por \(Text(verbatim: amountText))", bundle: .module)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Día \(item.effectiveDay)", bundle: .module)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @Environment(\.currency) private var currency

    /// Monto registrado al marcarlo (MAR-04).
    private var amountText: String { MoneyFormatter.string(item.record?.amount ?? .zero, currency: currency) }
}
