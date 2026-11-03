import SwiftUI
import WidgetKit

/// WID (§10.1): "Pagos de hoy" en pantalla de inicio y pantalla bloqueada.
struct TodayPaymentsWidget: Widget {
    let kind = "TodayPaymentsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayPaymentsProvider()) { entry in
            TodayPaymentsEntryView(entry: entry)
                .containerBackground(for: .widget) { WidgetPalette.background }  // WID-02
                .widgetURL(DeepLink.today.url)  // WID-05
        }
        .configurationDisplayName("Pagos de hoy")
        .description("Tus pagos de hoy y si ya los pagaste, sin mostrar montos.")
        .supportedFamilies([.accessoryInline, .accessoryRectangular, .systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayPaymentsEntryView: View {
    let entry: TodayEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch entry.content {
        case .unavailable:
            UnavailableView(family: family)
        case .snapshot(let snapshot):
            switch family {
            case .accessoryInline: InlineView(snapshot: snapshot)
            case .accessoryRectangular: RectangularView(snapshot: snapshot)
            case .systemMedium: ListView(snapshot: snapshot, maxRows: 3, showsProgress: false)
            case .systemLarge: ListView(snapshot: snapshot, maxRows: 7, showsProgress: true)
            default: SmallView(snapshot: snapshot)
            }
        }
    }
}
