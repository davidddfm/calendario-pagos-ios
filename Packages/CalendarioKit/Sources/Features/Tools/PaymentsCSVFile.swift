import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// HER-09: el archivo se genera cuando la hoja de compartir lo pide, no al dibujar el menú.
/// `nonisolated`: `ShareLink` usa la conformidad fuera del `MainActor`.
nonisolated public struct PaymentsCSVFile: Transferable, Sendable {
    private let makeFile: @MainActor @Sendable () throws -> URL

    /// - Parameter makeFile: ejecuta `ExportPaymentsUseCase` y devuelve la URL del CSV.
    public init(makeFile: @escaping @MainActor @Sendable () throws -> URL) {
        self.makeFile = makeFile
    }

    public static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            SentTransferredFile(try await file.makeFile())
        }
    }
}
