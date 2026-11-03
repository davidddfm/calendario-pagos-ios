import Domain
import SwiftUI
import WidgetKit

// WID-02: revisar cada tamaño en claro y oscuro desde el lienzo de Xcode.

#Preview("Mediano", as: .systemMedium) {
    TodayPaymentsWidget()
} timeline: {
    TodayEntry.sample(date: .now)
    TodayEntry(date: .now, content: .snapshot(TodaySnapshot(date: .now, items: [])))
}

#Preview("Grande", as: .systemLarge) {
    TodayPaymentsWidget()
} timeline: {
    TodayEntry.sample(date: .now)
}

#Preview("Pequeño", as: .systemSmall) {
    TodayPaymentsWidget()
} timeline: {
    TodayEntry.sample(date: .now)
    TodayEntry(date: .now, content: .unavailable)
}

#Preview("Rectangular", as: .accessoryRectangular) {
    TodayPaymentsWidget()
} timeline: {
    TodayEntry.sample(date: .now)
}

#Preview("Línea", as: .accessoryInline) {
    TodayPaymentsWidget()
} timeline: {
    TodayEntry.sample(date: .now)
}
