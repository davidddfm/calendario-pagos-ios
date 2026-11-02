import Domain
import Features
import Foundation
import Observation

enum AppTab: Hashable {
    case home, calendar, profile
}

/// Pantallas que se apilan dentro de una pestaña (§9.3). Las demás rutas llegan con sus pantallas.
enum AppRoute: Hashable {
    /// QUI-01
    case fortnight(Fortnight)
    /// HIS-01
    case history
    /// HIS-03
    case historyMonth(YearMonth)
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

/// Estado de navegación de la app (§9.3). Cada pestaña tiene su propia ruta, que se conserva al cambiar (NAV-02).
@Observable
final class AppRouter {
    var selectedTab: AppTab = .home
    var homePath: [AppRoute] = []
    var calendarPath: [AppRoute] = []
    var profilePath: [AppRoute] = []
    var sheet: AppSheet?
}
