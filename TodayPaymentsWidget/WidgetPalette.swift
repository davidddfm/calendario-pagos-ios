import SwiftUI
import UIKit

/// WID-02 (§10.5): grises fríos y verde "pagado", fijos e independientes del acento de la app.
enum WidgetPalette {
    static let background = dynamic(light: (0.95, 0.96, 0.98), dark: (0.11, 0.12, 0.14))
    static let primaryText = dynamic(light: (0.11, 0.13, 0.17), dark: (0.93, 0.94, 0.96))
    static let secondaryText = dynamic(light: (0.36, 0.40, 0.46), dark: (0.63, 0.67, 0.72))
    static let pending = dynamic(light: (0.55, 0.59, 0.65), dark: (0.48, 0.52, 0.58))
    static let paid = dynamic(light: (0.10, 0.55, 0.30), dark: (0.30, 0.78, 0.47))
    static let track = dynamic(light: (0.85, 0.87, 0.90), dark: (0.22, 0.24, 0.27))

    private static func dynamic(
        light: (Double, Double, Double), dark: (Double, Double, Double)
    ) -> Color {
        Color(
            uiColor: UIColor { traits in
                let rgb = traits.userInterfaceStyle == .dark ? dark : light
                return UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1)
            })
    }
}
