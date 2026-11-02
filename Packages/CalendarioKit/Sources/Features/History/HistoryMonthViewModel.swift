import Domain
import Foundation
import Observation

/// HIS-03 / HIS-04: un mes del historial, con correcciones.
@Observable
public final class HistoryMonthViewModel {
    public let period: YearMonth
    public let startDate: Date?
    public private(set) var state: LoadState<MonthStatement> = .idle
    public private(set) var actionError: UserFacingError?

    private let getStatement: GetMonthStatementUseCase
    private let togglePaid: TogglePaymentPaidUseCase

    public init(
        period: YearMonth,
        startDate: Date?,
        getStatement: GetMonthStatementUseCase,
        togglePaid: TogglePaymentPaidUseCase
    ) {
        self.period = period
        self.startDate = startDate
        self.getStatement = getStatement
        self.togglePaid = togglePaid
    }

    public func load() {
        do {
            state = .loaded(try getStatement.execute(period))
        } catch {
            state = .failed(UserFacingError(error))
        }
    }

    /// HIS-04: marca o desmarca en este mes, aunque sea pasado.
    public func togglePaid(_ item: MonthStatement.Item) {
        do {
            try togglePaid.execute(paymentID: item.id, period: period)
            load()
        } catch {
            actionError = UserFacingError(error)
        }
    }

    public func dismissActionError() { actionError = nil }
}
