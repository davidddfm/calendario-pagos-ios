import Domain
import Observation

/// CAL-01 y CAL-02.
@Observable
public final class CalendarViewModel {
    public private(set) var period: YearMonth
    public private(set) var state: LoadState<CalendarMonth> = .idle

    private let getMonth: GetCalendarMonthUseCase

    public init(getMonth: GetCalendarMonthUseCase) {
        self.getMonth = getMonth
        self.period = getMonth.currentPeriod
    }

    public var isShowingCurrentMonth: Bool { period == getMonth.currentPeriod }

    public func load() {
        do {
            state = .loaded(try getMonth.execute(period))
        } catch {
            state = .failed(UserFacingError(error))
        }
    }

    /// CAL-02: sin límite hacia atrás ni hacia adelante.
    public func showPreviousMonth() { show(period.adding(months: -1)) }
    public func showNextMonth() { show(period.adding(months: 1)) }
    public func showCurrentMonth() { show(getMonth.currentPeriod) }

    private func show(_ period: YearMonth) {
        self.period = period
        load()
    }
}
