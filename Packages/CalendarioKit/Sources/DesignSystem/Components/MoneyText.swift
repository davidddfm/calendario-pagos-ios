import Domain
import SwiftUI

/// Único componente que imprime montos (§9.6, MND-02).
public struct MoneyText: View {
    @Environment(\.currency) private var currency
    private let money: Money

    public init(_ money: Money) {
        self.money = money
    }

    public var body: some View {
        Text(verbatim: MoneyFormatter.string(money, currency: currency))
            .monospacedDigit()
    }
}

#if DEBUG
    #Preview {
        VStack {
            MoneyText(Money(minorUnits: 123_450))
            MoneyText(Money(minorUnits: -12_000)).environment(\.currency, .eur)
        }
    }
#endif
