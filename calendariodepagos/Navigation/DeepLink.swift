import Foundation

/// Enlaces `calendariodepagos://` (§9.3). Son entrada no confiable: solo se aceptan coincidencias exactas,
/// y un enlace solo navega; nunca crea, edita, marca, borra ni cambia ajustes.
enum DeepLink: String {
    /// NOT-09 y WID-05: Inicio con "Para hoy" a la vista.
    case today

    static let scheme = "calendariodepagos"

    /// Falla, y la URL se descarta, si el esquema, el host o la ruta no coinciden o si trae algo más.
    init?(url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            components.scheme?.lowercased() == Self.scheme,
            let host = components.host, let link = DeepLink(rawValue: host),
            components.path.isEmpty, components.query == nil, components.fragment == nil,
            components.user == nil, components.password == nil, components.port == nil
        else { return nil }
        self = link
    }

    var url: URL? {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.host = rawValue
        return components.url
    }
}
