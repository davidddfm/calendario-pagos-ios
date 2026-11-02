import Domain
import Features
import Foundation
import Testing

@testable import calendariodepagos

/// Integración de la raíz de composición con el almacén real en memoria (§9.2, §15).
@MainActor
@Suite("§9.2 · Raíz de composición")
struct AppContainerTests {
    @Test("MND-01 · Una instalación nueva empieza por el onboarding")
    func freshInstallNeedsOnboarding() throws {
        let container = try AppContainer(storage: .uiTesting)
        #expect(container.settings.load().needsOnboarding)
    }

    @Test("Crear un pago desde el formulario lo muestra en Inicio y avisa a las pantallas")
    func createFlowsToHome() throws {
        let container = try AppContainer(storage: .uiTesting)
        let initialVersion = container.tracker.version

        let form = container.makePaymentFormViewModel(mode: .create)
        form.name = "Renta"
        form.amountText = "500"
        form.save()

        let home = container.makeHomeViewModel()
        home.load()
        #expect(home.state.value?.allItems.map(\.name) == ["Renta"])
        #expect(container.tracker.version > initialVersion)
    }

    @Test func sheetModes() {
        let id = UUID()
        #expect(AppSheet.newPayment.formMode == .create)
        #expect(AppSheet.editPayment(id).formMode == .edit(id))
        #expect(AppSheet.newPayment.id != AppSheet.editPayment(id).id)
    }
}
