import Features
import Foundation
import Observation

enum AppTab: Hashable {
    case home, calendar, profile
}

enum AppSheet: Identifiable {
    /// NAV-01
    case newPayment
    case editPayment(UUID)

    var id: String {
        switch self {
        case .newPayment: "new"
        case .editPayment(let id): "edit-\(id.uuidString)"
        }
    }

    var formMode: PaymentFormViewModel.Mode {
        switch self {
        case .newPayment: .create
        case .editPayment(let id): .edit(id)
        }
    }
}

/// Estado de navegación de la app (§9.3). Las rutas por pestaña se agregan con sus pantallas (iteración 2).
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var sheet: AppSheet?
}
