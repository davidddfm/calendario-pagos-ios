import Domain
import Observation

/// QUI-01 a QUI-04.
@Observable
public final class FortnightViewModel {
    public let fortnight: Fortnight
    public private(set) var state: LoadState<FortnightDetail> = .idle
    public private(set) var actionError: UserFacingError?

    private let getDetail: GetFortnightDetailUseCase
    private let togglePaid: TogglePaymentPaidUseCase

    public init(fortnight: Fortnight, getDetail: GetFortnightDetailUseCase, togglePaid: TogglePaymentPaidUseCase) {
        self.fortnight = fortnight
        self.getDetail = getDetail
        self.togglePaid = togglePaid
    }

    public func load() {
        do {
            state = .loaded(try getDetail.execute(fortnight))
        } catch {
            state = .failed(UserFacingError(error))
        }
    }

    /// QUI-03: la quincena siempre es del mes actual (MAR-02).
    public func togglePaid(_ item: MonthStatement.Item) {
        do {
            try togglePaid.execute(paymentID: item.id)
            load()
        } catch {
            actionError = UserFacingError(error)
        }
    }

    public func dismissActionError() { actionError = nil }
}
