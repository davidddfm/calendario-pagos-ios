import XCTest

/// Flujos críticos de la iteración 1 (§15): MND-01, NAV-01, PAG-04, PAG-05, PAG-08.
final class PaymentsFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
    }

    @MainActor
    func testOnboardingAndFirstPayment() throws {
        completeOnboarding()
        XCTAssertTrue(app.staticTexts["Te damos la bienvenida"].waitForExistence(timeout: 5))  // PAG-08

        app.buttons["Crear mi primer pago"].tap()
        fillPayment(name: "Renta", amount: "1250")

        XCTAssertTrue(app.staticTexts["Renta"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["$1,250.00"].exists)  // MND-02
        XCTAssertTrue(app.staticTexts["Análisis quincenal"].exists)  // PAG-06
        attachScreenshot("Inicio con un pago")
    }

    /// NAV-01: desde cualquier pestaña, "+" (toque 1) y Guardar (toque 2).
    @MainActor
    func testCreateFromEveryTab() throws {
        completeOnboarding()
        for tab in ["Calendario", "Perfil", "Inicio"] {
            app.tabBars.buttons[tab].tap()
            app.buttons["addPayment"].firstMatch.tap()
            XCTAssertTrue(app.navigationBars["Nuevo pago"].waitForExistence(timeout: 5))
            app.buttons["Cancelar"].tap()
        }
    }

    @MainActor
    func testSearchAndDelete() throws {
        completeOnboarding()
        app.buttons["Crear mi primer pago"].tap()
        fillPayment(name: "Teléfono", amount: "30")
        app.buttons["addPayment"].firstMatch.tap()
        fillPayment(name: "Renta", amount: "500")
        XCTAssertTrue(app.staticTexts["Renta"].waitForExistence(timeout: 5))

        // PAG-05: sin acentos ni mayúsculas, mientras se escribe.
        let search = app.searchFields.firstMatch
        if !search.exists { app.swipeDown() }
        search.tap()
        search.typeText("TELEFONO")
        XCTAssertTrue(app.staticTexts["Teléfono"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Renta"].exists)
        search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "TELEFONO".count) + "\n")

        // PAG-04: eliminar pide confirmación.
        let rentRow = app.cells.containing(.staticText, identifier: "Renta").firstMatch
        XCTAssertTrue(rentRow.waitForExistence(timeout: 5))
        rentRow.swipeLeft()
        app.buttons["Eliminar"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["¿Eliminar este pago?"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Renta"].exists)
        app.buttons["Eliminar pago"].firstMatch.tap()

        let gone = NSPredicate(format: "exists == false")
        expectation(for: gone, evaluatedWith: app.staticTexts["Renta"])
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.staticTexts["Teléfono"].exists)
    }

    // MARK: - Ayudas

    private func completeOnboarding() {
        let dollar = app.buttons["Dólar estadounidense ($)"]
        XCTAssertTrue(dollar.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Continuar"].isEnabled)  // MND-01: hay que elegir antes de seguir
        dollar.tap()
        app.buttons["Continuar"].tap()
    }

    private func fillPayment(name: String, amount: String) {
        let nameField = app.textFields["payment.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        let amountField = app.textFields["payment.amount"]
        amountField.tap()
        amountField.typeText(amount)
        app.buttons["Guardar"].tap()
    }

    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
