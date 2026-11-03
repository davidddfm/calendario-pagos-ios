import SwiftUI

/// CAL-07 / HER-10: Exportar, ¿Puedo costearlo?, Detector de fugas y Plan 50/30/20.
public struct ToolsMenu: View {
    private let exportFile: PaymentsCSVFile
    private let onOpen: (Tool) -> Void

    public enum Tool: Hashable, Sendable {
        case affordability, leakDetector, budgetPlan
    }

    public init(exportFile: PaymentsCSVFile, onOpen: @escaping (Tool) -> Void) {
        self.exportFile = exportFile
        self.onOpen = onOpen
    }

    public var body: some View {
        Menu {
            ExportCSVLink(file: exportFile)
            Button {
                onOpen(.affordability)
            } label: {
                Label {
                    Text("¿Puedo costearlo?", bundle: .module)
                } icon: {
                    Image(systemName: "questionmark.circle")
                }
            }
            Button {
                onOpen(.leakDetector)
            } label: {
                Label {
                    Text("Detector de fugas", bundle: .module)
                } icon: {
                    Image(systemName: "drop")
                }
            }
            Button {
                onOpen(.budgetPlan)
            } label: {
                Label {
                    Text("Plan 50/30/20", bundle: .module)
                } icon: {
                    Image(systemName: "chart.pie")
                }
            }
        } label: {
            Label {
                Text("Herramientas", bundle: .module)
            } icon: {
                Image(systemName: "wrench.and.screwdriver")
            }
        }
        .accessibilityIdentifier("tools.menu")
    }
}

/// HER-09: hoja de compartir del sistema (Archivos, Mail, Mensajes, otras apps).
struct ExportCSVLink: View {
    let file: PaymentsCSVFile

    var body: some View {
        ShareLink(item: file, preview: SharePreview(Text("Pagos (CSV)", bundle: .module))) {
            Label {
                Text("Exportar CSV", bundle: .module)
            } icon: {
                Image(systemName: "square.and.arrow.up")
            }
        }
    }
}
