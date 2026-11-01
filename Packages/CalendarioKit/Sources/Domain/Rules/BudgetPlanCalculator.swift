/// HER-07: reparto ideal del salario. Solo informativo.
public struct BudgetPlan: Equatable, Sendable {
    public let needs: Money
    public let wants: Money
    public let savings: Money

    public init(needs: Money, wants: Money, savings: Money) {
        self.needs = needs
        self.wants = wants
        self.savings = savings
    }
}

public enum BudgetPlanCalculator {
    /// 50 % necesidades, 30 % deseos; el ahorro es el resto, así absorbe el redondeo y la suma da el salario.
    public static func plan(salary: Money) -> BudgetPlan {
        let needs = salary.percent(50)
        let wants = salary.percent(30)
        return BudgetPlan(needs: needs, wants: wants, savings: salary - needs - wants)
    }
}
