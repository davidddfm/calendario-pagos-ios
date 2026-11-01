// swift-tools-version: 6.2
import PackageDescription

// Iteración 0: solo `Domain`. Persistence, SystemServices, DesignSystem y Features (§4.2) se agregan
// en la iteración que los usa, porque SwiftPM no compila targets sin fuentes.
let package = Package(
    name: "CalendarioKit",
    defaultLocalization: "es",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Domain", targets: ["Domain"])
    ],
    targets: [
        .target(name: "Domain", resources: [.process("Resources")]),

        // Utilidades compartidas por las pruebas (§15). No es un producto: nunca se enlaza en la app.
        .target(name: "TestSupport", dependencies: ["Domain"]),

        .testTarget(name: "DomainTests", dependencies: ["Domain", "TestSupport"]),
    ]
)
