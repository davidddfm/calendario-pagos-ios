import XCTest

/// Humo: la app arranca sin cerrarse en cada configuración de apariencia (APA-01). Los flujos críticos (§15)
/// se agregan con cada iteración.
final class LaunchTests: XCTestCase {
    override class var runsForEachTargetApplicationUIConfiguration: Bool { true }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchReachesForeground() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Arranque"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
