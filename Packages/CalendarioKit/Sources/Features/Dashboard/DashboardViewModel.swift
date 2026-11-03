import Domain
import Observation

/// DAS-01 a DAS-04.
@Observable
public final class DashboardViewModel {
    public private(set) var state: LoadState<DashboardSummary> = .idle

    private let getDashboard: GetDashboardUseCase

    public init(getDashboard: GetDashboardUseCase) {
        self.getDashboard = getDashboard
    }

    public func load() {
        do {
            state = .loaded(try getDashboard.execute())
        } catch {
            state = .failed(UserFacingError(error))
        }
    }
}
