import XCTest

/// Flujos de la iteración 3 (§15): DAS-04, CFG-01, DAS-06, MND-03, CAL-07, HER-04, HER-03.
final class FinanceFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Onboarding en dólares y un pago "Renta" de 1,250.
    @MainActor
    private func launchWithRent() {
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
        app.textFields["payment.amount"].typeText("1250")
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.staticTexts["Renta"].waitForExistence(timeout: 5))
    }

    /// DAS-04 → Ajustes → CFG-01 → Dashboard con disponible; DAS-06.
    @MainActor
    func testSalaryFromDashboard() throws {
        launchWithRent()
        app.tabBars.buttons["Perfil"].tap()
        XCTAssertTrue(app.staticTexts["Configura tu salario"].waitForExistence(timeout: 5))
        let goToSettings = app.buttons["Ir a Ajustes"]
        XCTAssertTrue(goToSettings.waitForExistence(timeout: 5))
        goToSettings.tap()

        let salary = app.textFields["settings.salary"]
        XCTAssertTrue(salary.waitForExistence(timeout: 10))
        salary.tap()
        salary.typeText("2000")
        app.buttons["Guardar salario"].tap()
        XCTAssertTrue(app.buttons["Quitar salario"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(app.staticTexts["$750.00"].waitForExistence(timeout: 5))  // 2,000 − 1,250
        XCTAssertTrue(app.staticTexts["Tu fondo de emergencia"].exists)
        attachScreenshot("Dashboard con salario")

        app.swipeUp()
        app.buttons["Ver historial"].tap()
        XCTAssertTrue(app.staticTexts["Total pagado, últimos 6 meses"].waitForExistence(timeout: 5))
    }

    /// MND-03: advierte antes de cambiar y no convierte el monto.
    @MainActor
    func testChangeCurrency() throws {
        launchWithRent()
        app.buttons["home.menu"].tap()
        app.buttons["Configuración"].tap()
        let picker = app.buttons["settings.currency"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        app.buttons["Euro (€)"].firstMatch.tap()

        XCTAssertTrue(app.staticTexts["¿Cambiar la moneda?"].waitForExistence(timeout: 5))
        app.buttons["Cambiar a Euro (€)"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["€1,250.00"].waitForExistence(timeout: 5))
    }

    /// CAL-07: herramientas desde el Calendario; HER-04 y HER-03.
    @MainActor
    func testToolsFromCalendar() throws {
        launchWithRent()
        app.tabBars.buttons["Calendario"].tap()
        app.buttons["tools.menu"].tap()
        XCTAssertTrue(app.buttons["Exportar CSV"].waitForExistence(timeout: 5))  // HER-10
        app.buttons["Detector de fugas"].tap()
        XCTAssertTrue(app.staticTexts["$15,000.00"].waitForExistence(timeout: 5))  // 1,250 × 12
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["tools.menu"].tap()
        app.buttons["¿Puedo costearlo?"].tap()
        XCTAssertTrue(app.staticTexts["Configura tu salario"].waitForExistence(timeout: 5))  // S-05
        app.buttons["Ir a Ajustes"].tap()
        let salary = app.textFields["settings.salary"]
        XCTAssertTrue(salary.waitForExistence(timeout: 5))
        salary.tap()
        salary.typeText("5000")
        app.buttons["Guardar salario"].tap()
        XCTAssertTrue(app.buttons["Quitar salario"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()

        let amount = app.textFields["affordability.amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap()
        amount.typeText("200")
        XCTAssertTrue(app.staticTexts["Puedes costearlo"].waitForExistence(timeout: 5))  // ahorro 71 %
        attachScreenshot("¿Puedo costearlo?")
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
