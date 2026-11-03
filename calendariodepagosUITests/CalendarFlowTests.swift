import XCTest

/// Flujos de la iteración 4 (§15): CAL-01 a CAL-06, MAR-01 desde el detalle del día.
final class CalendarFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testDayDetailFromCalendar() throws {
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()
        let dollar = app.buttons["Dólar estadounidense ($)"]
        XCTAssertTrue(dollar.waitForExistence(timeout: 10))
        dollar.tap()
        app.buttons["Continuar"].tap()

        // El formulario propone el día de hoy.
        app.buttons["Crear mi primer pago"].tap()
        let nameField = app.textFields["payment.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Luz")
        app.textFields["payment.amount"].tap()
        app.textFields["payment.amount"].typeText("80")
        app.buttons["Guardar"].tap()
        XCTAssertTrue(app.staticTexts["Luz"].waitForExistence(timeout: 5))

        // CAL-01 / CAL-03: abrir el día de hoy.
        let calendar = Calendar.current
        let today = calendar.component(.day, from: .now)
        app.tabBars.buttons["Calendario"].tap()
        let todayCell = app.buttons["calendar.day.\(today)"]
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
        XCTAssertEqual(todayCell.value as? String, "1 pagos, 0 pagados")
        todayCell.tap()

        // CAL-04: casilla y progreso en el mes actual.
        let checkbox = app.buttons["paid.Luz"].firstMatch
        XCTAssertTrue(checkbox.waitForExistence(timeout: 5))
        checkbox.tap()
        XCTAssertTrue(
            app.staticTexts.matching(NSPredicate(format: "label CONTAINS '1 de 1 pagados'")).firstMatch
                .waitForExistence(timeout: 5))
        attachScreenshot("Detalle del día")

        // CAL-06: tocar el pago abre su edición.
        app.staticTexts["Luz"].tap()
        XCTAssertTrue(app.navigationBars["Editar pago"].waitForExistence(timeout: 5))
        app.buttons["Cancelar"].tap()
        app.navigationBars.buttons.firstMatch.tap()

        // CAL-02 / CAL-05: el mes siguiente proyecta el pago, sin casillas.
        app.buttons["calendar.next"].tap()
        XCTAssertTrue(app.buttons["Ir a hoy"].waitForExistence(timeout: 5))
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: .now) ?? .now
        let daysInNextMonth = calendar.range(of: .day, in: .month, for: nextMonth)?.count ?? 28
        app.buttons["calendar.day.\(min(today, daysInNextMonth))"].tap()
        XCTAssertTrue(app.staticTexts["Luz"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["paid.Luz"].exists)
        XCTAssertTrue(app.staticTexts["Para corregir lo pagado en otros meses, usa el Historial."].exists)
    }

    @MainActor
    private func attachScreenshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
