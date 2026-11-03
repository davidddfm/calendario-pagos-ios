// swift-tools-version: 6.2
import PackageDescription

let mainActorByDefault: [SwiftSetting] = [
    .defaultIsolation(MainActor.self),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
]

let package = Package(
    name: "CalendarioKit",
    defaultLocalization: "es",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "SystemServices", targets: ["SystemServices"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Features", targets: ["Features"]),
    ],
    targets: [
        .target(name: "Domain", resources: [.process("Resources")]),
        .target(name: "Persistence", dependencies: ["Domain"], resources: [.process("Resources")]),
        .target(name: "SystemServices", dependencies: ["Domain"]),
        .target(
            name: "DesignSystem", dependencies: ["Domain"], resources: [.process("Resources")],
            swiftSettings: mainActorByDefault),
        .target(
            name: "Features", dependencies: ["Domain", "DesignSystem"], resources: [.process("Resources")],
            swiftSettings: mainActorByDefault),

        // Utilidades compartidas por las pruebas (§15). No es un producto: nunca se enlaza en la app.
        .target(name: "TestSupport", dependencies: ["Domain"]),

        .testTarget(name: "DomainTests", dependencies: ["Domain", "TestSupport"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence", "Domain", "TestSupport"]),
        .testTarget(name: "SystemServicesTests", dependencies: ["SystemServices", "Domain", "TestSupport"]),
        .testTarget(
            name: "FeaturesTests", dependencies: ["Features", "Domain", "TestSupport"],
            swiftSettings: mainActorByDefault),
    ]
)
