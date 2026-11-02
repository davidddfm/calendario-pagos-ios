import Domain
import Foundation
import Observation

@Observable
public final class HomeViewModel {
    public private(set) var state: LoadState<HomeSummary> = .idle
    public var searchText = ""
    /// PAG-04: el borrado espera la confirmación del usuario.
    public var paymentPendingDeletion: MonthStatement.Item?
    public private(set) var actionError: UserFacingError?

    private let getSummary: GetHomeSummaryUseCase
    private let deletePayment: DeletePaymentUseCase

    public init(getSummary: GetHomeSummaryUseCase, deletePayment: DeletePaymentUseCase) {
        self.getSummary = getSummary
        self.deletePayment = deletePayment
    }

    public var isSearching: Bool { !TextSearch.normalize(searchText).isEmpty }

    /// PAG-05: filtra mientras se escribe, sin mayúsculas ni acentos.
    public var searchResults: [MonthStatement.Item] {
        guard let summary = state.value else { return [] }
        return summary.allItems.filter { TextSearch.matches($0.name, query: searchText) }
    }

    public func load() {
        do {
            state = .loaded(try getSummary.execute())
        } catch {
            state = .failed(UserFacingError(error))
        }
    }

    public func requestDeletion(of item: MonthStatement.Item) {
        paymentPendingDeletion = item
    }

    /// PAG-04: solo tras la confirmación.
    public func confirmDeletion() {
        guard let item = paymentPendingDeletion else { return }
        paymentPendingDeletion = nil
        do {
            try deletePayment.execute(id: item.id)
        } catch {
            actionError = UserFacingError(error)
        }
    }

    public func dismissActionError() { actionError = nil }
}
