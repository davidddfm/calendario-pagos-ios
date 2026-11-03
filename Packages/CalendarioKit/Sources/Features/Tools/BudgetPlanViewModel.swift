import Domain
import Observation

/// HER-07.
@Observable
public final class BudgetPlanViewModel {
    /// `loaded(nil)`: sin salario configurado (S-05).
    public private(set) var state: LoadState<BudgetPlan?> = .idle

    private let getPlan: GetBudgetPlanUseCase

    public init(getPlan: GetBudgetPlanUseCase) {
        self.getPlan = getPlan
    }

    public func load() {
        state = .loaded(getPlan.execute())
    }
}
