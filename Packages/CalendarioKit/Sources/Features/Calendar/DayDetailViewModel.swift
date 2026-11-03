import Domain
import Foundation
import Observation

/// CAL-03 a CAL-06.
@Observable
public final class DayDetailViewModel {
    public let date: Date
    public private(set) var state: LoadState<DayDetail> = .idle
    public private(set) var actionError: UserFacingError?

    private let getDetail: GetDayDetailUseCase
    private let togglePaid: TogglePaymentPaidUseCase

    public init(date: Date, getDetail: GetDayDetailUseCase, togglePaid: TogglePaymentPaidUseCase) {
        self.date = date
        self.getDetail = getDetail
        self.togglePaid = togglePaid
    }

    public func load() {
        do {
            state = .loaded(try getDetail.execute(date))
        } catch {
            state = .failed(UserFacingError(error))
        }
    }

    /// CAL-04: solo en el mes actual (MAR-02); los demás meses se corrigen desde el Historial (CAL-05).
    public func togglePaid(_ item: MonthStatement.Item) {
        guard state.value?.isEditable == true else { return }
        do {
            try togglePaid.execute(paymentID: item.id)
            load()
        } catch {
            actionError = UserFacingError(error)
        }
    }

    public func dismissActionError() { actionError = nil }
}
