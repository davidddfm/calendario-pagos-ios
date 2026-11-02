import Domain
import SwiftUI

/// CAT-03: mismo nombre e icono de categoría en todas las pantallas.
public struct CategoryBadge: View {
    private let category: PaymentCategory

    public init(_ category: PaymentCategory) {
        self.category = category
    }

    public var body: some View {
        Label {
            Text(category.localizedName)
        } icon: {
            Image(systemName: category.symbolName)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

extension PaymentCategory {
    /// Símbolo SF fijo por categoría (§9.6).
    public var symbolName: String {
        switch self {
        case .expenses: "cart"
        case .savings: "banknote"
        case .investments: "chart.line.uptrend.xyaxis"
        case .wellbeing: "heart"
        case .loans: "creditcard"
        case .transport: "car"
        case .utilities: "house"
        }
    }
}

#if DEBUG
    #Preview {
        List(PaymentCategory.allCases, id: \.self) { CategoryBadge($0) }
    }
#endif
