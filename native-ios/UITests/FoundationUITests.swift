import XCTest

final class FoundationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func launch(extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"] + extra
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
        for _ in 0..<12 {
            let top = app.navigationBars.firstMatch.frame.maxY + 12
            let bottom = app.tabBars.firstMatch.frame.minY - 12
            if element.exists && element.isHittable && element.frame.midY > top && element.frame.midY < bottom { return }
            let movingUp = !element.exists || element.frame.midY > bottom
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingUp ? 0.65 : 0.35))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: movingUp ? 0.40 : 0.60))
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(element.isHittable)
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
        app.terminate()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Me"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.tabBars.buttons["Me"].isSelected)
    }

    func testDarkModeAndAccessibilityText() {
        let app = launch(extra: ["--ui-dark",
                                 "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        for name in ["Feed", "Today", "Train", "Health", "Me"] {
            app.tabBars.buttons[name].tap()
            XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5))
            capture(app, "M0-\(name)-dark-AX5")
        }
        app.tabBars.buttons["Health"].tap()
        let sleep = app.buttons["ring-sleep"]
        XCTAssertTrue(sleep.exists)
        sleep.tap()
        XCTAssertTrue(app.navigationBars["Sleep"].exists)
    }
}
