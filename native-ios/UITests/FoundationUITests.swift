import XCTest

final class FoundationUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    private func tab(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.buttons["tab-\(name.lowercased())"]
    }

    private func assertCapsule(_ app: XCUIApplication) {
        let names = ["Feed", "Today", "Train", "Health", "Me"]
        XCTAssertFalse(app.tabBars.firstMatch.isHittable, "Stock tab bar must not duplicate the capsule")
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "tab-")).count, 5)
        let window = app.windows.firstMatch.frame
        var last: CGFloat = -1
        for name in names {
            let button = tab(app, name)
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            XCTAssertGreaterThan(button.frame.minX, last)
            XCTAssertGreaterThanOrEqual(button.frame.minX, window.minX)
            XCTAssertLessThanOrEqual(button.frame.maxX, window.maxX)
            XCTAssertLessThanOrEqual(button.frame.maxY, window.maxY)
            last = button.frame.maxX
        }
    }

    private func selectChip(_ app: XCUIApplication, _ picker: String, _ name: String) {
        let button = app.buttons["\(picker)-\(name)"]
        let row = app.scrollViews[picker]
        if row.exists {
            // Chip rows scroll horizontally.
            reveal(row, in: app)
            for _ in 0..<3 {
                if button.isHittable { break }
                row.swipeLeft()
            }
        } else {
            // Underlined section tabs have no container identifier (it would mask child IDs).
            reveal(button, in: app)
        }
        XCTAssertTrue(button.isHittable)
        button.tap()
        XCTAssertTrue(button.isSelected)
    }

    private func launch(state: String = "missing", theme: String = "light", size: String = "large", width: Int? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-reset", "--ui-health-state=\(state)", "--ui-theme=\(theme)", "--ui-text-size=\(size)"]
        if let width { app.launchArguments.append("--ui-content-width=\(width)") }
        app.launch()
        let found = tab(app, "Today").waitForExistence(timeout: 15)
        if !found {
            capture(app, "UI-launch-navigation-failure")
            print("NAVIGATION FAILURE TREE:\n\(app.debugDescription)")
        }
        XCTAssertTrue(found)
        return app
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        if name.hasPrefix("UI-") {
            // AX snapshots can precede the compositor after a tab/section change on loaded CI.
            // Flush one frame, then allow the native transition to settle in the separate test process.
            _ = app.screenshot()
            Thread.sleep(forTimeInterval: 0.6)
        }
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<24 {
            let top = app.navigationBars.firstMatch.frame.maxY + 12
            let bottom = tab(app, "Feed").frame.minY - 12
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
        for theme in ["light", "dark"] {
            let app = launch(theme: theme)
            assertCapsule(app)
            for name in ["Feed", "Today", "Train", "Health", "Me"] {
                let button = tab(app, name)
                button.tap()
                XCTAssertTrue(button.isSelected)
                XCTAssertEqual(button.value as? String, "selected")
                XCTAssertTrue(app.navigationBars[name].waitForExistence(timeout: 5))
                if name != "Health" {
                    assertScreenContent(app, name)
                    XCTAssertFalse(app.buttons["ring-sleep"].exists)
                }
                capture(app, "UI-\(name)-\(theme)")
            }
            tab(app, "Feed").tap()
            app.buttons["open-groups"].tap()
            XCTAssertTrue(app.navigationBars["Groups"].waitForExistence(timeout: 5))
            capture(app, "UI-Groups-Events-\(theme)")
            selectChip(app, "groups-section", "Clubs")
            XCTAssertTrue(app.staticTexts["The Comeback Club"].exists)
            capture(app, "UI-Groups-Clubs-\(theme)")
            app.navigationBars.buttons.element(boundBy: 0).tap()
            selectChip(app, "feed-filter", "Strength")
            XCTAssertFalse(app.staticTexts["Morning Easy Run"].exists)
            XCTAssertTrue(app.staticTexts["Strength Foundation"].exists)

            tab(app, "Train").tap()
            app.navigationBars.buttons["Maps"].tap()
            XCTAssertTrue(app.navigationBars["Maps"].waitForExistence(timeout: 5))
            capture(app, "UI-Maps-\(theme)")
            selectChip(app, "route-filter", "Short Loop")
            XCTAssertTrue(app.staticTexts["1.6 km"].exists)

            tab(app, "Today").tap()
            let choose = app.buttons["choose-plan"]
            reveal(choose, in: app)
            choose.tap()
            XCTAssertTrue(app.navigationBars["เลือกแผน"].waitForExistence(timeout: 5))
            capture(app, "UI-Library-\(theme)")

            tab(app, "Me").tap()
            selectChip(app, "profile-section", "Activities")
            XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "profile-activities-empty").firstMatch.exists)
            capture(app, "UI-Profile-Activities-\(theme)")
            selectChip(app, "profile-section", "Gallery")
            capture(app, "UI-Profile-Gallery-\(theme)")
            selectChip(app, "profile-section", "More")
            XCTAssertTrue(app.buttons["Apple Health และอุปกรณ์"].exists)
            capture(app, "UI-Profile-More-\(theme)")
            app.terminate()
        }
    }

    func testHealthDetailsAndNoRingsInMe() {
        for state in ["notRequested", "unavailable", "failed", "missing", "loading"] {
            let fixture = launch(state: state)
            tab(fixture, "Health").tap()
            let stateView = fixture.descendants(matching: .any).matching(identifier: "health-state-\(state)").firstMatch
            reveal(stateView, in: fixture)
            XCTAssertTrue(stateView.exists)
            if state == "unavailable" { XCTAssertFalse(fixture.buttons["health-connection"].exists) }
            capture(fixture, "M0-Health-state-\(state)")
            fixture.terminate()
        }
        let app = launch()
        tab(app, "Health").tap()
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
        tab(app, "Me").tap()
        XCTAssertFalse(app.buttons["ring-sleep"].exists)
        XCTAssertFalse(app.buttons["ring-recovery"].exists)
        XCTAssertFalse(app.buttons["ring-strain"].exists)
    }

    func testIndependentStacksAndRestoredTab() {
        let app = launch()
        tab(app, "Today").tap()
        let connection = app.buttons["today-health-connection"]
        reveal(connection, in: app)
        connection.tap()
        XCTAssertTrue(app.navigationBars["Apple Health"].waitForExistence(timeout: 5))
        tab(app, "Health").tap()
        app.buttons["ring-sleep"].tap()
        tab(app, "Today").tap()
        XCTAssertTrue(app.navigationBars["Apple Health"].exists)
        tab(app, "Health").tap()
        XCTAssertTrue(app.navigationBars["Sleep"].exists)
        tab(app, "Me").tap()
        app.launchArguments.removeAll { $0 == "--ui-reset" }
        app.terminate()
        app.launch()
        XCTAssertTrue(tab(app, "Me").waitForExistence(timeout: 10))
        XCTAssertTrue(tab(app, "Me").isSelected)
    }

    func testDarkModeAndAccessibilityText() {
        // Expanded matrix measured335s on SE before responsive Feed scrolling assertions.
        // Keep all scenarios; seven minutes stays inside the existing CLI maximum.
        executionTimeAllowance = 420
        let device = ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? ""
        let expectedWidth: CGFloat = device.contains("iPhone SE (3rd generation)") ? 375 : 393
        XCTAssertTrue(device.contains("iPhone SE (3rd generation)") || device.contains("iPhone 16"), "Unexpected simulator: \(device)")
        for theme in ["light", "dark"] {
            for size in ["large", "xLarge", "AX5"] {
                let app = launch(state: "stale", theme: theme, size: size)
                assertCapsule(app)
                XCTAssertEqual(app.windows.firstMatch.frame.width, expectedWidth, accuracy: 1)
                verifyHealthLayout(app, theme: theme, size: size, name: "\(device)-\(theme)-\(size)")
                if size == "AX5" && theme == "dark" {
                    for name in ["Feed", "Today", "Train", "Me"] {
                        tab(app, name).tap()
                        assertCapsule(app)
                        assertScreenContent(app, name)
                        if name == "Feed" {
                            // Groups is a circular header control; it must stay reachable at AX5.
                            let groups = app.buttons["open-groups"]
                            XCTAssertTrue(groups.isHittable)
                            XCTAssertGreaterThanOrEqual(groups.frame.width, 44)
                            capture(app, "UI-Feed-header-dark-AX5")
                        }
                        capture(app, "UI-\(name)-dark-AX5")
                    }
                }
                app.terminate()
            }
        }
        // A hosted 320pt content container, not a claim of Display Zoom/device simulation.
        let hosted = launch(state: "stale", size: "xLarge", width: 320)
        verifyHealthLayout(hosted, theme: "light", size: "xLarge", name: "hosted-320-xLarge")
        XCTAssertEqual(hosted.scrollViews.firstMatch.frame.width, 320, accuracy: 1)
    }

    /// Feed remains labeled sample content; Today/Train/Me now render real local state.
    private func assertScreenContent(_ app: XCUIApplication, _ name: String) {
        let id = name == "Feed" ? "sample-banner" : "screen-\(name.lowercased())"
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: id).firstMatch.waitForExistence(timeout: 5), id)
        if name != "Feed" {
            XCTAssertFalse(app.descendants(matching: .any).matching(identifier: "sample-banner").firstMatch.exists,
                           "\(name) must not present fictional sample data as real progress")
        }
    }

    /// Plan enrolment, Live Workout draft recovery after termination, and Partial logging keeping
    /// the same session current. Runs offline against an isolated UI-testing store.
    func testTrainingFlowPersistsDraftAndPartial() {
        let app = launch()
        tab(app, "Today").tap()
        let choose = app.buttons["choose-plan"]
        reveal(choose, in: app)
        choose.tap()
        let program = app.buttons["program-sprint100"]
        XCTAssertTrue(program.waitForExistence(timeout: 5))
        reveal(program, in: app)
        program.tap()
        let start = app.buttons["start-plan"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        reveal(start, in: app)
        start.tap()
        let startLive = app.buttons["program-start-live"]
        XCTAssertTrue(startLive.waitForExistence(timeout: 5))
        reveal(startLive, in: app)
        startLive.tap()
        XCTAssertTrue(app.navigationBars["Live Workout"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["live-title"].label, "Sprint A + Strength A")
        let warmup = app.buttons["checklist-warmup-0"]
        reveal(warmup, in: app)
        warmup.tap()
        XCTAssertTrue(warmup.isSelected)
        let next = app.buttons["live-next"]
        reveal(next, in: app)
        next.tap()
        let mark = app.buttons["live-mark"]
        reveal(mark, in: app)
        mark.tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "live-count").firstMatch.label.hasPrefix("1"))
        capture(app, "UI-LiveWorkout-light")

        app.terminate()
        app.launchArguments.removeAll { $0 == "--ui-reset" }
        app.launch()
        XCTAssertTrue(tab(app, "Today").waitForExistence(timeout: 15))
        tab(app, "Today").tap()
        let resume = app.buttons["resume-live"]
        XCTAssertTrue(resume.waitForExistence(timeout: 5), "Draft must survive termination")
        reveal(resume, in: app)
        resume.tap()
        XCTAssertTrue(app.navigationBars["Live Workout"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "live-count").firstMatch.label.hasPrefix("1"),
                      "Restored sprint step and completed rep")
        let finish = app.buttons["live-finish"]
        reveal(finish, in: app)
        finish.tap()
        let partial = app.buttons["บันทึก Partial"]
        XCTAssertTrue(partial.waitForExistence(timeout: 5))
        partial.tap()
        let result = app.descendants(matching: .any).matching(identifier: "live-result").firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(result.label.contains("ทำบางส่วน"))
        capture(app, "UI-LiveWorkout-partial-result")
        app.buttons["live-done"].tap()
        tab(app, "Today").tap()
        let title = app.staticTexts["next-session-title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        XCTAssertEqual(title.label, "Sprint A + Strength A", "Partial keeps the same session current")
        capture(app, "UI-Today-after-partial")
    }

    private func verifyHealthLayout(_ app: XCUIApplication, theme: String, size: String, name: String) {
        tab(app, "Health").tap()
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
