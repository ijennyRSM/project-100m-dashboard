import XCTest

final class FoundationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(state: String = "missing", theme: String = "light", size: String = "large", width: Int? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-health-state=\(state)", "--ui-theme=\(theme)", "--ui-text-size=\(size)"]
        if let width { app.launchArguments.append("--ui-content-width=\(width)") }
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 15))
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<24 {
            let top = app.navigationBars.firstMatch.frame.maxY + 12
            let bottom = app.tabBars.firstMatch.frame.minY - 12
            if element.exists && element.isHittable && element.frame.midY > top && element.frame.midY < bottom { return }
            let movingUp = !element.exists || element.frame.midY > bottom
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingUp ? 0.65 : 0.35))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingUp ? 0.40 : 0.60))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(element.isHittable, "Could not reveal \(element.identifier)")
    }

    private func assertInBounds(_ element: XCUIElement, app: XCUIApplication) {
        reveal(element, in: app)
        XCTAssertTrue(element.isHittable)
        let bounds = app.scrollViews.firstMatch.frame
        XCTAssertGreaterThanOrEqual(element.frame.minX, bounds.minX - 1)
        XCTAssertLessThanOrEqual(element.frame.maxX, bounds.maxX + 1)
        XCTAssertGreaterThan(element.frame.width, 0)
    }

    func testFiveTabsAndLabeledExamples() {
        let app = launch()
        let names = ["Feed", "Today", "Train", "Health", "Me"]
        XCTAssertEqual(app.tabBars.buttons.count, 5)
        var lastX: CGFloat = -1
        for name in names {
            let button = app.tabBars.buttons[name]
            XCTAssertGreaterThan(button.frame.midX, lastX)
            lastX = button.frame.midX
            button.tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5))
            if name != "Health" {
                XCTAssertTrue(app.otherElements["sample-banner"].exists || app.staticTexts["sample-banner"].exists)
            }
            capture(app, "M0-\(name)-light")
        }
    }

    func testHealthDetailsAndNoRingsInMe() {
        for state in ["notRequested", "unavailable", "failed", "missing", "loading"] {
            let fixture = launch(state: state)
            fixture.tabBars.buttons["Health"].tap()
            let stateView = fixture.descendants(matching: .any).matching(identifier: "health-state-\(state)").firstMatch
            reveal(stateView, in: fixture)
            XCTAssertTrue(stateView.exists)
            if state == "unavailable" { XCTAssertFalse(fixture.buttons["health-connection"].exists) }
            capture(fixture, "M0-Health-state-\(state)")
            fixture.terminate()
        }
        let app = launch()
        app.tabBars.buttons["Health"].tap()
        for (id, title) in [("sleep", "Sleep"), ("recovery", "Recovery"), ("strain", "Strain")] {
            let ring = app.buttons["ring-\(id)"]
            XCTAssertTrue(ring.waitForExistence(timeout: 5))
            XCTAssertTrue(ring.isHittable)
            XCTAssertEqual(ring.value as? String, "ยังไม่คำนวณ")
            ring.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 5))
            capture(app, "M0-\(title)-detail-missing")
            app.navigationBars.buttons.element(boundBy: 0).tap()
        }
        app.tabBars.buttons["Me"].tap()
        XCTAssertFalse(app.buttons["ring-sleep"].exists)
        XCTAssertFalse(app.buttons["ring-recovery"].exists)
        XCTAssertFalse(app.buttons["ring-strain"].exists)
    }

    func testIndependentStacksAndRestoredTab() {
        let app = launch()
        app.tabBars.buttons["Today"].tap()
        let next = app.buttons["next-workout-example"]
        reveal(next, in: app)
        next.tap()
        XCTAssertTrue(app.navigationBars["ตัวอย่าง Session"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Health"].tap()
        app.buttons["ring-sleep"].tap()
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.navigationBars["ตัวอย่าง Session"].exists)
        app.tabBars.buttons["Health"].tap()
        XCTAssertTrue(app.navigationBars["Sleep"].exists)
        app.tabBars.buttons["Me"].tap()
        app.launchArguments.removeAll { $0 == "--ui-reset" }
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Me"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Me"].isSelected)
    }

    func testDarkModeAndAccessibilityText() {
        // Seven cold launches plus AX5 scrolling/captures measured ~273s on the SE runner.
        // Keep every assertion; give this matrix test six minutes, other tests stay bounded.
        executionTimeAllowance = 360
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
        let expectedWidth: CGFloat = device.contains("iPhone SE (3rd generation)") ? 375 : 393
        XCTAssertTrue(device.contains("iPhone SE (3rd generation)") || device.contains("iPhone 16"), "Unexpected simulator: \(device)")
        for theme in ["light", "dark"] {
            for size in ["large", "xLarge", "AX5"] {
                let app = launch(state: "stale", theme: theme, size: size)
                XCTAssertEqual(app.windows.firstMatch.frame.width, expectedWidth, accuracy: 1)
                verifyHealthLayout(app, theme: theme, size: size, name: "\(device)-\(theme)-\(size)")
                app.terminate()
            }
        }
        // A hosted 320pt content container, not a claim of Display Zoom/device simulation.
        let hosted = launch(state: "stale", size: "xLarge", width: 320)
        verifyHealthLayout(hosted, theme: "light", size: "xLarge", name: "hosted-320-xLarge")
        XCTAssertEqual(hosted.scrollViews.firstMatch.frame.width, 320, accuracy: 1)
    }

    private func verifyHealthLayout(_ app: XCUIApplication, theme: String, size: String, name: String) {
        app.tabBars.buttons["Health"].tap()
        let probe = app.descendants(matching: .any).matching(identifier: "health-presentation").firstMatch
        reveal(probe, in: app)
        XCTAssertEqual(probe.value as? String, "\(theme)|\(size)", "Actual SwiftUI color scheme and Dynamic Type must match")
        for id in ["sleep", "recovery", "strain"] {
            let ring = app.buttons["ring-\(id)"]
            assertInBounds(ring, app: app)
            capture(app, "M0-Health-\(name)-\(id)")
        }
        for id in ["rhr", "hrv"] {
            let tile = app.descendants(matching: .any).matching(identifier: "metric-\(id)").firstMatch
            assertInBounds(tile, app: app)
            XCTAssertTrue(tile.label.contains("ค่าล่าสุดภายใน 21 วัน"))
            XCTAssertTrue(tile.label.contains("วัดเมื่อ"))
            capture(app, "M0-Health-\(name)-\(id)")
        }
    }
}
