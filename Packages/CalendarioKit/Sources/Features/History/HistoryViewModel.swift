import Domain
import Observation

/// HIS-01 / HIS-02.
@Observable
public final class HistoryViewModel {
    public private(set) var state: LoadState<HistoryOverview> = .idle

    private let getOverview: GetHistoryOverviewUseCase

    public init(getOverview: GetHistoryOverviewUseCase) {
        self.getOverview = getOverview
    }

    public func load() {
        do {
            state = .loaded(try getOverview.execute())
        } catch {
            state = .failed(UserFacingError(error))
        }
    }
}
