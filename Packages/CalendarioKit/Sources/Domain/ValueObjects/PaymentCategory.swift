import Foundation

/// CAT-01: lista fija. Los valores crudos son estables y se persisten; nunca se renombran.
public enum PaymentCategory: String, CaseIterable, Codable, Sendable {
    case expenses = "gastos"
    case savings = "ahorros"
    case investments = "inversiones"
    case wellbeing = "bienestar"
    case loans = "prestamos"
    case transport = "transportes"
    case utilities = "servicios"

    /// PAG-02 / CAT-02
    public static let `default`: PaymentCategory = .expenses

    /// Valor robusto ante datos desconocidos.
    public init(storedValue: String) { self = PaymentCategory(rawValue: storedValue) ?? .default }

    /// CAT-03: nombre único para todas las pantallas, el widget y el CSV.
    public var localizedName: LocalizedStringResource {
        switch self {
        case .expenses: LocalizedStringResource("Gastos", bundle: .domain)
        case .savings: LocalizedStringResource("Ahorros", bundle: .domain)
        case .investments: LocalizedStringResource("Inversiones", bundle: .domain)
        case .wellbeing: LocalizedStringResource("Bienestar", bundle: .domain)
        case .loans: LocalizedStringResource("Préstamos", bundle: .domain)
        case .transport: LocalizedStringResource("Transportes", bundle: .domain)
        case .utilities: LocalizedStringResource("Servicios", bundle: .domain)
        }
    }

    /// Clasificación para la regla 50/30/20 (supuesto S-03).
    public var budgetBucket: BudgetBucket {
        switch self {
        case .utilities, .transport, .loans, .expenses: .needs
        case .wellbeing: .wants
        case .savings, .investments: .savings
        }
    }
}

extension LocalizedStringResource.BundleDescription {
    /// Catálogo de cadenas del módulo `Domain` (un literal sin bundle buscaría en el de la app).
    static let domain: Self = .atURL(Bundle.module.bundleURL)
}
