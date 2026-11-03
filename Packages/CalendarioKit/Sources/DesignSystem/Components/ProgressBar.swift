import SwiftUI

/// DAS-01: barra con color **y** texto, para no depender solo del color (§9.6).
public struct ProgressBar: View {
    private let value: Double
    private let tint: Color
    private let label: Text

    /// - Parameter value: proporción; se dibuja recortada a 0...1 aunque la supere.
    public init(value: Double, tint: Color, label: Text) {
        self.value = value
        self.tint = tint
        self.label = label
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ProgressView(value: min(max(value, 0), 1))
                .tint(tint)
            label
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

#if DEBUG
    #Preview {
        VStack(spacing: 24) {
            ProgressBar(value: 0.4, tint: .green, label: Text(verbatim: "40 % del salario"))
            ProgressBar(value: 1.3, tint: .orange, label: Text(verbatim: "130 % del salario"))
        }
        .padding()
    }
#endif
