import Foundation
import Testing

@testable import calendariodepagos

/// §9.3: los enlaces profundos son entrada no confiable.
@MainActor
@Suite("NOT-09 / WID-05 · Enlaces profundos")
struct DeepLinkTests {
    @Test("Solo se acepta el enlace exacto")
    func valid() throws {
        #expect(DeepLink(url: try #require(URL(string: "calendariodepagos://today"))) == .today)
        #expect(DeepLink.today.url?.absoluteString == "calendariodepagos://today")
    }

    @Test(
        "Cualquier otra forma se descarta",
        arguments: [
            "calendariodepagos://today/extra",
            "calendariodepagos://today?delete=all",
            "calendariodepagos://today#x",
            "calendariodepagos://settings",
            "otraapp://today",
            "https://today",
            "calendariodepagos://user@today",
            "calendariodepagos://today:8080",
        ])
    func invalid(string: String) throws {
        #expect(DeepLink(url: try #require(URL(string: string))) == nil)
    }

    @Test("NOT-09 · El enlace lleva a Inicio con \"Para hoy\" a la vista y solo navega")
    func routerHandlesToday() {
        let router = AppRouter()
        router.selectedTab = .calendar
        router.homePath = [.history]
        router.sheet = .newPayment
        router.handle(.today)
        #expect(router.selectedTab == .home)
        #expect(router.homePath.isEmpty)
        #expect(router.sheet == nil)
        #expect(router.homeScrollRequest == 1)
    }
}
