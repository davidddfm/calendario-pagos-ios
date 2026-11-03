import Domain
import SwiftUI
import WidgetKit

/// Resumen de una línea: pendientes de hoy, "Todo al día" o "Sin pagos hoy".
struct SummaryText: View {
    let snapshot: TodaySnapshot

    var body: some View {
        if snapshot.totalCount == 0 {
            Text("Sin pagos hoy")
        } else if snapshot.pendingCount == 0 {
            Text("Todo al día")
        } else {
            Text("^[\(snapshot.pendingCount) pago pendiente](inflect: true) hoy")
        }
    }
}

/// `.accessoryInline`: pantalla bloqueada, una línea.
struct InlineView: View {
    let snapshot: TodaySnapshot

    var body: some View {
        Label {
            SummaryText(snapshot: snapshot)
        } icon: {
            Image(systemName: snapshot.pendingCount == 0 ? "checkmark.circle" : "calendar")
        }
    }
}

/// `.accessoryRectangular`: pantalla bloqueada, con icono y avance.
struct RectangularView: View {
    let snapshot: TodaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Label("Pagos de hoy", systemImage: "calendar")
                .font(.headline)
                .widgetAccentable()
            SummaryText(snapshot: snapshot)
            if snapshot.totalCount > 0 {
                Text("\(snapshot.paidCount) de \(snapshot.totalCount) pagados")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// `.systemSmall`: número grande de pendientes.
struct SmallView: View {
    let snapshot: TodaySnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pagos de hoy")
                .font(.caption.weight(.semibold))
                .foregroundStyle(WidgetPalette.secondaryText)
            Spacer(minLength: 0)
            if snapshot.totalCount == 0 {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundStyle(WidgetPalette.pending)
                Text("Sin pagos hoy")
                    .font(.headline)
                    .foregroundStyle(WidgetPalette.primaryText)
            } else if snapshot.pendingCount == 0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(WidgetPalette.paid)
                    .widgetAccentable()
                Text("¡Todo al día!")
                    .font(.headline)
                    .foregroundStyle(WidgetPalette.primaryText)
            } else {
                Text(snapshot.pendingCount, format: .number)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(WidgetPalette.primaryText)
                    .widgetAccentable()
                    .accessibilityLabel(Text("^[\(snapshot.pendingCount) pago pendiente](inflect: true)"))
                Text("\(snapshot.paidCount) de \(snapshot.totalCount) pagados")
                    .font(.subheadline)
                    .foregroundStyle(WidgetPalette.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

/// Sin acceso al almacén (§7.2).
struct UnavailableView: View {
    let family: WidgetFamily

    var body: some View {
        switch family {
        case .accessoryInline, .accessoryRectangular:
            Text("Abre la app para ver tus pagos")
        default:
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "calendar")
                    .font(.title2)
                    .foregroundStyle(WidgetPalette.pending)
                Text("Abre la app para ver tus pagos")
                    .font(.subheadline)
                    .foregroundStyle(WidgetPalette.primaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
