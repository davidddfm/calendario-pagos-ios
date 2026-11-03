import XCTest

/// Flujos de la iteración 5 (§15): SEG-01 a SEG-03, NOT-02, NOT-05.
/// Con `-ui-testing`, el permiso de avisos está concedido y la autenticación siempre tiene éxito.
final class SystemFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLockAfterBackground() throws {
        launchAndOpenSettings()

        // SEG-01 / SEG-02: activar el bloqueo y pedirlo de inmediato.
        let lockToggle = app.switches["settings.appLock"]
        scrollTo(lockToggle)
        lockToggle.switches.firstMatch.tap()
        let gracePeriod = app.buttons["settings.gracePeriod"]
        XCTAssertTrue(gracePeriod.waitForExistence(timeout: 5))
        gracePeriod.tap()
        app.buttons["Inmediatamente"].firstMatch.tap()

        // SEG-03: al volver del segundo plano no se ve ningún dato.
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts["Calendario de Pagos está bloqueado"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Renta"].exists)
        attachScreenshot("Bloqueada")

        // El autenticador de prueba concede el acceso.
        let lockGone = NSPredicate(format: "exists == false")
        expectation(for: lockGone, evaluatedWith: app.staticTexts["Calendario de Pagos está bloqueado"])
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.switches["settings.appLock"].exists)
    }

    @MainActor
    func testRemindersToggle() throws {
        launchAndOpenSettings()
        let toggle = app.switches["settings.reminders"]
        scrollTo(toggle)
        XCTAssertEqual(toggle.value as? String, "1")  // NOT-01: activados por defecto
        XCTAssertTrue(app.staticTexts["Hora del aviso"].exists)
        toggle.switches.firstMatch.tap()  // NOT-05
        XCTAssertFalse(app.staticTexts["Hora del aviso"].waitForExistence(timeout: 2))
        XCTAssertEqual(toggle.value as? String, "0")
    }

    // MARK: - Ayudas

    @MainActor
    private func launchAndOpenSettings() {
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        let dollar = app.buttons["Dólar estadounidense ($)"]
        XCTAssertTrue(dollar.waitForExistence(timeout: 10))
        dollar.tap()
        app.buttons["Continuar"].tap()
        app.buttons["Crear mi primer pago"].tap()
        let nameField = app.textFields["payment.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Renta")
        app.textFields["payment.amount"].tap()
        app.textFields["payment.amount"].typeText("500")
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.staticTexts["Renta"].waitForExistence(timeout: 5))
        app.buttons["home.menu"].tap()
        app.buttons["Configuración"].tap()
        XCTAssertTrue(app.textFields["settings.salary"].waitForExistence(timeout: 5))
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement) {
        var attempts = 0
        while !element.isHittable && attempts < 5 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(element.isHittable)
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
