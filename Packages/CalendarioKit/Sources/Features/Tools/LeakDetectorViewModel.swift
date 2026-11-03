import Domain
import Observation

/// HER-04 a HER-06.
@Observable
public final class LeakDetectorViewModel {
    public private(set) var state: LoadState<LeakReport> = .idle

    private let getReport: GetLeakReportUseCase

    public init(getReport: GetLeakReportUseCase) {
        self.getReport = getReport
    }

    public func load() {
        do {
            state = .loaded(try getReport.execute())
        } catch {
            state = .failed(UserFacingError(error))
        }
    }
}
