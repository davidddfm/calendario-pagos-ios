import Domain
import SwiftUI

extension EnvironmentValues {
    /// MND-02: la raíz de la app la reemplaza por la moneda elegida. El valor por defecto solo afecta al formato.
    @Entry public var currency: Currency = .usd
}
