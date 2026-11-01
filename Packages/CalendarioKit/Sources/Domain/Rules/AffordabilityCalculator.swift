/// HER-01: tipo del nuevo gasto.
public enum ExpenseKind: Sendable, CaseIterable {
    case need, want
}

/// HER-03: semáforo de ¿Puedo costearlo?
public enum TrafficLight: Sendable {
    case green, yellow, red
}

/// Distribución recalculada con el nuevo gasto (HER-02).
public struct AffordabilityResult: Equatable, Sendable {
    public let salary: Money
    public let needs: Money
    public let wants: Money
    /// Lo que queda para ahorro; incluye los pagos de Ahorros e Inversiones. Puede ser negativo.
    public let savings: Money
    public let light: TrafficLight

    public init(salary: Money, needs: Money, wants: Money, savings: Money, light: TrafficLight) {
        self.salary = salary
        self.needs = needs
        self.wants = wants
        self.savings = savings
        self.light = light
    }

    public var needsShare: Double { needs.ratio(to: salary) }
    public var wantsShare: Double { wants.ratio(to: salary) }
    public var savingsShare: Double { savings.ratio(to: salary) }
}

/// ¿Puedo costearlo? (HER-01 a HER-03, supuesto S-03).
public enum AffordabilityCalculator {
    /// - Parameter activePayments: pagos activos en el mes actual.
    public static func evaluate(
        salary: Money,
        newExpense: Money,
        kind: ExpenseKind,
        activePayments: [Payment]
    ) -> AffordabilityResult {
        func total(_ bucket: BudgetBucket) -> Money {
            activePayments.filter { $0.category.budgetBucket == bucket }.map(\.amount).sum()
        }
        let needs = total(.needs) + (kind == .need ? newExpense : .zero)
        let wants = total(.wants) + (kind == .want ? newExpense : .zero)
        let savings = salary - needs - wants
        return AffordabilityResult(
            salary: salary,
            needs: needs,
            wants: wants,
            savings: savings,
            light: light(savings: savings, salary: salary, newExpense: newExpense)
        )
    }

    /// HER-03: verde ≥ 15 %, amarillo de 10 % a menos de 15 %, rojo < 10 % o gasto mayor que el ingreso.
    /// Compara enteros para que los umbrales exactos no dependan de la coma flotante.
    public static func light(savings: Money, salary: Money, newExpense: Money) -> TrafficLight {
        guard salary > .zero, newExpense <= salary else { return .red }
        let savingsTimes100 = savings.minorUnits * 100
        if savingsTimes100 >= salary.minorUnits * 15 { return .green }
        if savingsTimes100 >= salary.minorUnits * 10 { return .yellow }
        return .red
    }
}
