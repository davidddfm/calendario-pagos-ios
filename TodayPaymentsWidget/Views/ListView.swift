import AppIntents
import Domain
import SwiftUI
import WidgetKit

/// `.systemMedium` y `.systemLarge`: fecha y pagos de hoy con su casilla (WID-07).
struct ListView: View {
    let snapshot: TodaySnapshot
    let maxRows: Int
    /// Solo Grande: barra "2 de 3 pagados".
    let showsProgress: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            if showsProgress, snapshot.totalCount > 0 {
                ProgressView(value: Double(snapshot.paidCount), total: Double(snapshot.totalCount))
                    .tint(WidgetPalette.paid)
                    .widgetAccentable()
                    .accessibilityHidden(true)
            }
            if snapshot.items.isEmpty {
                Spacer(minLength: 0)
                Text("Sin pagos hoy")
                    .font(.subheadline)
                    .foregroundStyle(WidgetPalette.secondaryText)
            } else {
                ForEach(snapshot.items.prefix(maxRows)) { item in
                    // WID-07: solo la casilla cambia el estado; el resto del widget abre la app (WID-05).
                    Toggle(isOn: item.isPaid, intent: TogglePaymentPaidIntent(paymentID: item.id)) {
                        Text(item.name)
                    }
                    .toggleStyle(PaidToggleStyle())
                }
                if snapshot.items.count > maxRows {
                    Text("y \(snapshot.items.count - maxRows) más")
                        .font(.caption)
                        .foregroundStyle(WidgetPalette.secondaryText)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Pagos de hoy")
                .font(.headline)
                .foregroundStyle(WidgetPalette.primaryText)
            Spacer()
            if snapshot.totalCount > 0 {
                Text("\(snapshot.paidCount) de \(snapshot.totalCount) pagados")
                    .font(.caption)
                    .foregroundStyle(WidgetPalette.secondaryText)
            } else {
                Text(snapshot.date, format: .dateTime.weekday(.wide).day().month())
                    .font(.caption)
                    .foregroundStyle(WidgetPalette.secondaryText)
            }
        }
    }
}

/// Círculo "Pendiente" o palomita y tachado "Pagado": el color nunca es el único indicador (§14.6).
struct PaidToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(configuration.isOn ? WidgetPalette.paid : WidgetPalette.pending)
                    .widgetAccentable()
                configuration.label
                    .font(.subheadline)
                    .strikethrough(configuration.isOn)
                    .foregroundStyle(configuration.isOn ? WidgetPalette.secondaryText : WidgetPalette.primaryText)
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityValue(configuration.isOn ? Text("Pagado") : Text("Pendiente"))
    }
}
