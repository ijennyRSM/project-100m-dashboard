import XCTest
@testable import P100Core

final class CatalogTests: XCTestCase {
    func testSessionCountsMatchWebDefinitions() {
        XCTAssertEqual(TrainingCatalog.sessions(for: "sprint100").count, 60)
        XCTAssertEqual(TrainingCatalog.sessions(for: "run5k").count, 24)
        XCTAssertEqual(TrainingCatalog.sessions(for: "strength").count, 24)
        XCTAssertEqual(TrainingCatalog.sessions(for: "wellness").count, 18)
        XCTAssertEqual(TrainingCatalog.sessions(for: "run10k").count, 0)
        XCTAssertFalse(TrainingCatalog.template("run10k")!.isAvailable)
        XCTAssertEqual(TrainingCatalog.templates.map(\.id), ["sprint100", "run5k", "run10k", "strength", "wellness"])
    }

    func testSprintPrescriptionsPortedExactly() {
        let s = TrainingCatalog.sessions(for: "sprint100")
        XCTAssertEqual(s.first?.key, "w1-1")
        XCTAssertEqual(s.first?.summary, "Sprint 4 × 20m · 60–70% + เวทขา")
        XCTAssertEqual(s.first?.components.strength?.first?.sets, 2)
        let w4 = s.first { $0.key == "w4-3" }!
        XCTAssertEqual(w4.summary, "เวทขา 1 เซต/ท่า")
        let trial = s.first { $0.key == "w12-4" }!
        XCTAssertEqual(trial.title, "100M Time Trial")
        XCTAssertEqual(trial.components.sprint, SprintPrescription(reps: 1, meters: 100, effort: "ทดสอบเมื่อพร้อม"))
        XCTAssertEqual(s.first { $0.key == "w12-5" }?.summary, "40–45 นาที · สบาย")
        XCTAssertEqual(s.first { $0.key == "w7-1" }?.components.strength?.first?.sets, 3)
        let fiveK = TrainingCatalog.sessions(for: "run5k")
        XCTAssertEqual(fiveK.first { $0.key == "w8-1" }?.components.duration, 35)
        XCTAssertEqual(fiveK.first { $0.key == "w8-3" }?.components.duration, 45)
        XCTAssertEqual(TrainingCatalog.sessions(for: "wellness").first { $0.key == "w6-1" }?.summary, "เดิน 30 นาที")
    }
}

final class EngineTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func started(_ template: String = "sprint100") throws -> TrainingState {
        var state = TrainingState.empty(now: t0)
        try TrainingEngine.startPlan(&state, templateId: template, now: t0, id: "plan-1")
        return state
    }

    func next(_ state: TrainingState) -> String? { TrainingEngine.overview(TrainingEngine.activePlan(state)!).next?.key }

    func testCompletedAdvancesPartialStays() throws {
        var state = try started()
        XCTAssertEqual(next(state), "w1-1")
        try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .partial), now: t0)
        XCTAssertEqual(next(state), "w1-1", "Partial keeps the session current")
        try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .completed, rpe: 7), now: t0)
        XCTAssertEqual(next(state), "w1-2")
        let overview = TrainingEngine.overview(TrainingEngine.activePlan(state)!)
        XCTAssertEqual(overview.completed, 1)
        XCTAssertEqual(overview.percent, 2)
    }

    func testSkipRequiresExplicitConfirmation() throws {
        var state = try started()
        XCTAssertThrowsError(try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .skipped))) {
            XCTAssertEqual($0 as? TrainingError, .skipNeedsConfirmation)
        }
        XCTAssertEqual(next(state), "w1-1")
        try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .skipped, skipConfirmedAt: t0), now: t0)
        XCTAssertEqual(next(state), "w1-2")
        XCTAssertEqual(TrainingEngine.activePlan(state)?.records.last?.skipConfirmedAt, t0)
    }

    func testCalendarTimeNeverAdvancesOrSkips() throws {
        var state = try started()
        try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .completed), now: t0.addingTimeInterval(86_400 * 400))
        XCTAssertEqual(next(state), "w1-2", "A year-later log still advances exactly one session")
    }

    func testResolvedSessionsAndValidation() throws {
        var state = try started()
        try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .completed), now: t0)
        XCTAssertThrowsError(try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .partial)))
        XCTAssertThrowsError(try TrainingEngine.record(&state, key: "w99-1", input: AttemptInput(status: .completed)))
        XCTAssertThrowsError(try TrainingEngine.record(&state, key: "w1-2", input: AttemptInput(status: .completed, rpe: 11)))
        XCTAssertThrowsError(try TrainingEngine.startPlan(&state, templateId: "run10k")) {
            XCTAssertEqual($0 as? TrainingError, .templateUnavailable)
        }
    }

    func testHistoryNewestFirstWithTitles() throws {
        var state = try started()
        try TrainingEngine.record(&state, key: "w1-1", input: AttemptInput(status: .completed), now: t0)
        try TrainingEngine.record(&state, key: "w1-2", input: AttemptInput(status: .partial), now: t0.addingTimeInterval(60))
        let rows = TrainingEngine.history(state)
        XCTAssertEqual(rows.map(\.sessionTitle), ["Easy Run", "Sprint A + Strength A"])
        XCTAssertEqual(rows.first?.templateName, "100M — The Comeback")
    }
}

final class LiveWorkoutTests: XCTestCase {
    let t0 = Date(timeIntervalSince1970: 1_800_000_000)

    func started() throws -> TrainingState {
        var state = TrainingState.empty(now: t0)
        try TrainingEngine.startPlan(&state, templateId: "sprint100", now: t0, id: "plan-1")
        try LiveWorkoutEngine.start(&state, now: t0)
        return state
    }

    func testStepsFromSessionComponents() throws {
        let state = try started()
        let draft = try XCTUnwrap(state.activeLive)
        XCTAssertEqual(draft.key, "w1-1")
        XCTAssertEqual(draft.steps.map(\.id), ["warmup", "sprint", "strength-0", "strength-1", "strength-2", "strength-3", "cooldown"])
        XCTAssertEqual(draft.steps[0].total, 3, "Sprint warm-up checklist from session text")
        XCTAssertEqual(draft.steps[1].total, 4)
        XCTAssertEqual(draft.steps[1].restSeconds, 150)
    }

    func testMarkRestPauseAndElapsed() throws {
        var state = try started()
        try LiveWorkoutEngine.toggleChecklist(&state, stepId: "warmup", itemId: "warmup-1", now: t0)
        XCTAssertEqual(state.activeLive?.steps[0].done, 1)
        try LiveWorkoutEngine.markUnit(&state, now: t0)
        try LiveWorkoutEngine.markUnit(&state, now: t0)
        XCTAssertTrue(state.activeLive!.steps[0].isComplete)
        try LiveWorkoutEngine.next(&state, now: t0)
        try LiveWorkoutEngine.markUnit(&state, now: t0.addingTimeInterval(10))
        XCTAssertEqual(state.activeLive?.restRemaining(at: t0.addingTimeInterval(10)), 150)
        try LiveWorkoutEngine.undoUnit(&state, now: t0.addingTimeInterval(11))
        XCTAssertEqual(state.activeLive?.steps[1].done, 0)
        XCTAssertNil(state.activeLive?.restUntil)
        try LiveWorkoutEngine.togglePause(&state, now: t0.addingTimeInterval(100))
        XCTAssertEqual(state.activeLive!.elapsed(at: t0.addingTimeInterval(5000)), 100, accuracy: 0.001)
        try LiveWorkoutEngine.togglePause(&state, now: t0.addingTimeInterval(5000))
        XCTAssertEqual(state.activeLive!.elapsed(at: t0.addingTimeInterval(5060)), 160, accuracy: 0.001)
    }

    func testPartialFinishKeepsSessionAndRestoresProgress() throws {
        var state = try started()
        try LiveWorkoutEngine.goTo(&state, index: 1, now: t0)
        try LiveWorkoutEngine.markUnit(&state, now: t0)
        try LiveWorkoutEngine.markUnit(&state, now: t0)
        try LiveWorkoutEngine.update(&state, notes: "ลมแรง", rpe: 6, now: t0)
        let attempt = try LiveWorkoutEngine.finish(&state, now: t0.addingTimeInterval(1800))
        XCTAssertEqual(attempt.status, .partial)
        XCTAssertEqual(attempt.duration, 30)
        XCTAssertEqual(attempt.repsDone, 2)
        XCTAssertEqual(attempt.rpe, 6)
        XCTAssertNil(state.activeLive)
        XCTAssertEqual(TrainingEngine.overview(TrainingEngine.activePlan(state)!).next?.key, "w1-1")
        try LiveWorkoutEngine.start(&state, now: t0.addingTimeInterval(86_400))
        XCTAssertEqual(state.activeLive?.steps[1].done, 2, "Completed sprint reps restored from the Partial attempt")
    }

    func testCompleteFinishAdvancesAndBlocksSecondDraft() throws {
        var state = try started()
        XCTAssertThrowsError(try LiveWorkoutEngine.start(&state, key: "w1-2", now: t0)) {
            XCTAssertEqual($0 as? TrainingError, .liveWorkoutInProgress)
        }
        for index in state.activeLive!.steps.indices {
            try LiveWorkoutEngine.goTo(&state, index: index, now: t0)
            for _ in 0..<state.activeLive!.steps[index].total { try LiveWorkoutEngine.markUnit(&state, now: t0) }
        }
        XCTAssertTrue(state.activeLive!.isComplete)
        let attempt = try LiveWorkoutEngine.finish(&state, now: t0.addingTimeInterval(20))
        XCTAssertEqual(attempt.status, .completed)
        XCTAssertEqual(attempt.duration, 1)
        XCTAssertEqual(TrainingEngine.overview(TrainingEngine.activePlan(state)!).next?.key, "w1-2")
    }
}

final class StatsTests: XCTestCase {
    var calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Bangkok")!
        c.firstWeekday = 2
        return c
    }()
    // Wednesday 2026-11-11 14:00 Bangkok
    let now = Date(timeIntervalSince1970: 1_794_380_400)

    func attempt(_ daysAgo: Double, _ status: AttemptStatus, minutes: Int?) -> SessionAttempt {
        SessionAttempt(id: UUID().uuidString, key: "w1-1", at: now.addingTimeInterval(-daysAgo * 86_400), status: status,
                       mode: "quick", date: "", duration: minutes, rpe: nil, repsDone: nil, sets: "", notes: "",
                       source: "self-reported", components: nil, skipConfirmedAt: nil)
    }

    func testWeeklyBucketsAreZeroFilledAndIgnoreSkips() {
        let rows = [attempt(0, .completed, minutes: 30), attempt(1, .partial, minutes: 10),
                    attempt(1, .skipped, minutes: 99), attempt(15, .completed, minutes: 40)]
        let weeks = TrainingStats.weekly(rows, now: now, count: 12, calendar: calendar)
        XCTAssertEqual(weeks.count, 12)
        XCTAssertEqual(weeks.last?.sessions, 2)
        XCTAssertEqual(weeks.last?.minutes, 40)
        XCTAssertEqual(weeks[weeks.count - 3].minutes, 40)
        XCTAssertEqual(weeks.reduce(0) { $0 + $1.sessions }, 3)
    }

    func testWeekStreak() {
        XCTAssertEqual(TrainingStats.weekStreak([], now: now, calendar: calendar), 0)
        let alive = [attempt(8, .completed, minutes: 20), attempt(15, .partial, minutes: 20)]
        XCTAssertEqual(TrainingStats.weekStreak(alive, now: now, calendar: calendar), 2, "Streak survives an empty current week")
        let broken = [attempt(0, .completed, minutes: 20), attempt(15, .completed, minutes: 20)]
        XCTAssertEqual(TrainingStats.weekStreak(broken, now: now, calendar: calendar), 1)
        XCTAssertEqual(TrainingStats.weekStreak([attempt(0, .skipped, minutes: nil)], now: now, calendar: calendar), 0)
    }
}

final class RepositoryTests: XCTestCase {
    var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("p100-tests-" + UUID().uuidString)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: root)
    }

    let userA = "6A1F3C1E-0000-4000-8000-000000000001"
    let userB = "6A1F3C1E-0000-4000-8000-000000000002"

    func testRoundTripAndAccountIsolation() throws {
        let a = try XCTUnwrap(TrainingRepository.forScope(.user(userA), root: root))
        let b = try XCTUnwrap(TrainingRepository.forScope(.user(userB), root: root))
        let guest = try XCTUnwrap(TrainingRepository.forScope(.guest, root: root))
        var state = TrainingState.empty(now: Date(timeIntervalSince1970: 1_800_000_000))
        try TrainingEngine.startPlan(&state, templateId: "run5k", now: state.updatedAt, id: "p")
        try LiveWorkoutEngine.start(&state, now: state.updatedAt)
        try a.save(state)
        let (loaded, outcome) = a.load()
        XCTAssertEqual(outcome, .loaded)
        XCTAssertEqual(loaded, state)
        XCTAssertEqual(b.load().1, .fresh)
        XCTAssertEqual(guest.load().1, .fresh)
        XCTAssertNotEqual(a.directory, b.directory)
        XCTAssertNil(TrainingRepository.forScope(.user("../../etc"), root: root))
    }

    func testCorruptAndNewerDocumentsArePreservedNotOverwritten() throws {
        let repo = try XCTUnwrap(TrainingRepository.forScope(.guest, root: root))
        try FileManager.default.createDirectory(at: repo.directory, withIntermediateDirectories: true)
        try Data("{not json".utf8).write(to: repo.fileURL)
        let (state, outcome) = repo.load(now: Date(timeIntervalSince1970: 1))
        XCTAssertEqual(state.plans, [])
        guard case .recovered(_, let backup) = outcome else { return XCTFail("expected recovery") }
        XCTAssertEqual(try String(contentsOf: repo.directory.appendingPathComponent(backup), encoding: .utf8), "{not json")
        try Data(#"{"schemaVersion":99}"#.utf8).write(to: repo.fileURL)
        guard case .recovered(let reason, _) = repo.load(now: Date(timeIntervalSince1970: 2)).1 else { return XCTFail() }
        XCTAssertTrue(reason.contains("newer"))
        XCTAssertFalse(FileManager.default.fileExists(atPath: repo.fileURL.path))
    }
}
