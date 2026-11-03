import DesignSystem
import Domain
import SwiftUI

/// Pestaña Calendario: mes con los días que tienen pagos (CAL-01, CAL-02).
public struct CalendarView: View {
    @State private var viewModel: CalendarViewModel
    @Environment(DataChangeTracker.self) private var changes
    private let onOpenDay: (Date) -> Void

    public init(viewModel: CalendarViewModel, onOpenDay: @escaping (Date) -> Void) {
        _viewModel = State(initialValue: viewModel)
        self.onOpenDay = onOpenDay
    }

    public var body: some View {
        content
            .navigationTitle(Text("Calendario", bundle: .module))
            .task(id: changes.version) { viewModel.load() }
    }

    /// Siempre la misma `List` (ver `HistoryView`).
    private var content: some View {
        List {
            if let month = viewModel.state.value {
                Section {
                    header(month)
                    MonthGrid(month: month, onOpenDay: onOpenDay)
                        .padding(.vertical, 4)
                }
                Section {
                    HStack {
                        Text("Total del mes", bundle: .module)
                        Spacer()
                        MoneyText(month.total)
                    }
                    .accessibilityElement(children: .combine)
                } footer: {
                    Text("Toca un día para ver sus pagos.", bundle: .module)
                }
            }
        }
        .overlay { LoadStateOverlay(state: viewModel.state, retry: viewModel.load) }
    }

    /// CAL-02
    private func header(_ month: CalendarMonth) -> some View {
        HStack {
            Button(action: viewModel.showPreviousMonth) {
                Label {
                    Text("Mes anterior", bundle: .module)
                } icon: {
                    Image(systemName: "chevron.left")
                }
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityIdentifier("calendar.previous")
            Spacer()
            VStack(spacing: 2) {
                Text(month.startDate, format: .dateTime.month(.wide).year())
                    .font(.headline)
                    .accessibilityIdentifier("calendar.title")
                if !viewModel.isShowingCurrentMonth {
                    Button(action: viewModel.showCurrentMonth) {
                        Text("Ir a hoy", bundle: .module)
                            .font(.caption)
                    }
                }
            }
            Spacer()
            Button(action: viewModel.showNextMonth) {
                Label {
                    Text("Mes siguiente", bundle: .module)
                } icon: {
                    Image(systemName: "chevron.right")
                }
                .labelStyle(.iconOnly)
                .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityIdentifier("calendar.next")
        }
        .buttonStyle(.borderless)
    }
}

/// CAL-01: cuadrícula de 7 columnas; los días con pagos llevan fondo y punto.
private struct MonthGrid: View {
    let month: CalendarMonth
    let onOpenDay: (Date) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            // Un solo `ForEach` con identidades separadas: los encabezados y los días no deben compartir ids.
            ForEach(cells) { cell in
                switch cell {
                case .weekday(_, let symbol):
                    Text(verbatim: symbol)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                case .empty:
                    Color.clear.frame(height: 44)
                case .day(let day):
                    DayCell(day: day, isToday: day.day == month.today) { onOpenDay(day.date) }
                }
            }
        }
    }

    private var cells: [GridCell] {
        month.weekdaySymbols.enumerated().map { GridCell.weekday($0.offset, $0.element) }
            + (0..<month.leadingEmptyDays).map(GridCell.empty)
            + month.days.map(GridCell.day)
    }

    private enum GridCell: Identifiable {
        case weekday(Int, String)
        case empty(Int)
        case day(CalendarMonth.Day)

        var id: String {
            switch self {
            case .weekday(let index, _): "weekday-\(index)"
            case .empty(let index): "empty-\(index)"
            case .day(let day): "day-\(day.day)"
            }
        }
    }
}

private struct DayCell: View {
    let day: CalendarMonth.Day
    let isToday: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(verbatim: "\(day.day)")
                    .font(.body.weight(isToday ? .bold : .regular))
                    .foregroundStyle(isToday ? Color.accentColor : Color.primary)
                Circle()
                    .fill(day.hasPayments ? (day.paidCount == day.count ? Color.green : Color.accentColor) : .clear)
                    .frame(width: 6, height: 6)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(day.hasPayments ? Color.accentColor.opacity(0.12) : .clear)
            }
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 8).strokeBorder(Color.accentColor, lineWidth: 1.5)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(day.date, format: .dateTime.weekday(.wide).day().month(.wide)))
        .accessibilityValue(accessibilityValue)
        .accessibilityAddTraits(isToday ? .isSelected : [])
        .accessibilityIdentifier("calendar.day.\(day.day)")
    }

    private var accessibilityValue: Text {
        day.hasPayments
            ? Text("\(day.count) pagos, \(day.paidCount) pagados", bundle: .module)
            : Text("Sin pagos", bundle: .module)
    }
}
