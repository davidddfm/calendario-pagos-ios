import Foundation

/// PAG-05: búsqueda por nombre que ignora mayúsculas y acentos.
public enum TextSearch {
    public static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Una consulta vacía coincide con todo.
    public static func matches(_ name: String, query: String) -> Bool {
        let normalizedQuery = normalize(query)
        return normalizedQuery.isEmpty || normalize(name).contains(normalizedQuery)
    }
}
