import Domain
import SwiftUI

/// HER-03: semáforo con color, icono y texto.
public struct TrafficLightView: View {
    private let light: TrafficLight
    private let message: Text

    public init(_ light: TrafficLight, message: Text) {
        self.light = light
        self.message = message
    }

    public var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbolName)
                .font(.largeTitle)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                title
                    .font(.headline)
                message
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private var title: Text {
        switch light {
        case .green: Text("Puedes costearlo", bundle: .module)
        case .yellow: Text("Con precaución", bundle: .module)
        case .red: Text("No te lo recomendamos", bundle: .module)
        }
    }

    private var symbolName: String {
        switch light {
        case .green: "checkmark.circle.fill"
        case .yellow: "exclamationmark.triangle.fill"
        case .red: "xmark.octagon.fill"
        }
    }

    private var color: Color {
        switch light {
        case .green: .green
        case .yellow: .yellow
        case .red: .red
        }
    }
}

#if DEBUG
    #Preview {
        List {
            TrafficLightView(.green, message: Text(verbatim: "Tu ahorro queda en 20 %."))
            TrafficLightView(.yellow, message: Text(verbatim: "Tu ahorro queda en 12 %."))
            TrafficLightView(.red, message: Text(verbatim: "Tu ahorro queda en 5 %."))
        }
    }
#endif
