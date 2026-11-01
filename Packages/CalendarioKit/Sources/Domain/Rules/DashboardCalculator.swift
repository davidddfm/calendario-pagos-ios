/// Cálculos del Dashboard (DAS-01 a DAS-04).
public enum DashboardCalculator {
    /// - Parameter activePayments: pagos activos en el mes actual.
    public static func summary(salary: Money?, activePayments: [Payment]) -> DashboardSummary {
        let totalMonthly = activePayments.map(\.amount).sum()

        let availability = salary.map { salary in
            let spentRatio = totalMonthly.ratio(to: salary)
            // Comparación entera para que el 50 % exacto sea "healthy" sin errores de coma flotante.
            let isHealthy = totalMonthly.minorUnits * 2 <= salary.minorUnits
            return DashboardSummary.Availability(
                salary: salary,
                available: salary - totalMonthly,
                spentRatio: spentRatio,
                level: isHealthy ? .healthy : .warning
            )
        }

        let totalsByCategory = Dictionary(grouping: activePayments, by: \.category)
            .mapValues { $0.map(\.amount).sum() }
        let categoryShares = PaymentCategory.allCases
            .compactMap { category -> DashboardSummary.CategoryShare? in
                guard let total = totalsByCategory[category], total > .zero else { return nil }
                return DashboardSummary.CategoryShare(
                    category: category, total: total, share: total.ratio(to: totalMonthly))
            }
            // `sorted` es estable: a igual total se conserva el orden fijo de las categorías.
            .sorted { $0.total > $1.total }

        return DashboardSummary(
            totalMonthly: totalMonthly,
            availability: availability,
            categoryShares: categoryShares,
            emergencyFund: DashboardSummary.EmergencyFund(
                threeMonths: totalMonthly.multiplied(by: 3),
                sixMonths: totalMonthly.multiplied(by: 6),
                twelveMonths: totalMonthly.multiplied(by: 12)
            )
        )
    }
}
