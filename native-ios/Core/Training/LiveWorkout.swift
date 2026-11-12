import Foundation

struct ChecklistItem: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var done: Bool
}

/// One step of a Live Workout. `done/total` counts checklist items, sprint reps, strength sets
/// or a single completion, matching the web Live Workout engine (`live-workout.js`).
struct LiveStep: Codable, Hashable, Identifiable {
    var id: String
    var kind: String
    var title: String
    var detail: String
    var total: Int
    var done: Int
    var restSeconds: Int
    var checklist: [ChecklistItem]?
    var isComplete: Bool { done >= total }
}

/// Durable, per-account Live Workout draft. Timers are stored as wall-clock anchors so the
/// draft survives termination: elapsed = accumulated + (now - runningSince) while running.
struct LiveWorkoutDraft: Codable, Hashable {
    var version: Int
    var planId: String
    var key: String
    var title: String
    var startedAt: Date
    var runningSince: Date?
    var accumulatedSeconds: Double
    var index: Int
    var steps: [LiveStep]
    var restUntil: Date?
    var notes: String
    var rpe: Int?
    var updatedAt: Date

    var isPaused: Bool { runningSince == nil }
    var isComplete: Bool { steps.allSatisfy(\.isComplete) }
    var unitsDone: Int { steps.reduce(0) { $0 + min($1.done, $1.total) } }
    var unitsTotal: Int { steps.reduce(0) { $0 + $1.total } }
    var currentStep: LiveStep? { steps.indices.contains(index) ? steps[index] : nil }

    func elapsed(at now: Date) -> TimeInterval {
        max(0, accumulatedSeconds + (runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0))
    }

    func restRemaining(at now: Date) -> TimeInterval {
        guard let restUntil else { return 0 }
        return max(0, restUntil.timeIntervalSince(now))
    }
}

enum LiveWorkoutEngine {
    /// Warm-up checklist items are taken from the reviewed session text, not invented drills.
    static func warmupChecklist(for session: TrainingSession) -> [ChecklistItem] {
        var titles: [String]
        if session.kind == .sprint {
            titles = ["วอร์มอัพ 15–20 นาที", "A-March / A-Skip", "ฝึกเร่งจากท่ายืน"]
            if session.title == "100M Time Trial" { titles.append("แข็งแรง ฟื้นตัวดี และไม่มีอาการเจ็บ") }
        } else {
            titles = ["ค่อย ๆ เพิ่มอุณหภูมิร่างกาย"]
        }
        return titles.enumerated().map { ChecklistItem(id: "warmup-\($0.offset)", title: $0.element, done: false) }
    }

    static func steps(for session: TrainingSession, restoring previous: SessionAttempt? = nil) -> [LiveStep] {
        let checklist = warmupChecklist(for: session)
        var rows = [LiveStep(id: "warmup", kind: "warmup", title: "Warm-up · เตรียมร่างกาย",
                             detail: "ค่อย ๆ เพิ่มอุณหภูมิร่างกายและฝึกท่าวิ่งตามแผน", total: checklist.count, done: 0,
                             restSeconds: 0, checklist: checklist)]
        let parts = session.components
        if let sprint = parts.sprint {
            rows.append(LiveStep(id: "sprint", kind: "sprint", title: "Sprint \(sprint.meters)m",
                                 detail: "\(sprint.reps) เที่ยว · \(sprint.effort) · พักระหว่างเที่ยวจนฟื้นตัว",
                                 total: sprint.reps, done: 0, restSeconds: sprint.meters >= 50 ? 240 : 150))
        }
        if let duration = parts.duration {
            rows.append(LiveStep(id: "cardio", kind: "cardio", title: session.kind == .walk ? "เดินแบบสบาย" : "Easy Run / Run–Walk",
                                 detail: "เป้าหมาย \(duration) นาที · พูดคุยเป็นประโยคได้", total: 1, done: 0, restSeconds: 0))
        }
        for (i, exercise) in (parts.strength ?? []).enumerated() {
            rows.append(LiveStep(id: "strength-\(i)", kind: "strength", title: exercise.name,
                                 detail: "\(exercise.sets) เซต × \(exercise.reps)", total: exercise.sets, done: 0, restSeconds: 90))
        }
        rows.append(LiveStep(id: "cooldown", kind: "cooldown", title: "Cooldown · ผ่อนลง",
                             detail: "เดินเบา ๆ ลดความหนัก และเช็กอาการก่อนจบ", total: 1, done: 0, restSeconds: 0))
        // Partial: restore completed components from the latest Partial attempt.
        if let saved = previous?.components {
            let byId = Dictionary(saved.map { ($0.id, $0.done) }, uniquingKeysWith: { _, b in b })
            for i in rows.indices {
                guard let done = byId[rows[i].id] else { continue }
                rows[i].done = min(max(0, done), rows[i].total)
                if var list = rows[i].checklist {
                    for j in list.indices { list[j].done = j < rows[i].done }
                    rows[i].checklist = list
                }
            }
        }
        return rows
    }

    /// Starts (or resumes) a Live Workout for `key` or the plan's next session.
    @discardableResult
    static func start(_ state: inout TrainingState, key: String? = nil, now: Date = Date()) throws -> LiveWorkoutDraft {
        guard let plan = TrainingEngine.activePlan(state) else { throw TrainingError.noActivePlan }
        if key == nil, let existing = state.activeLive, existing.planId == plan.id { return existing }
        let overview = TrainingEngine.overview(plan)
        guard let session = key.flatMap({ k in overview.sessions.first { $0.key == k } }) ?? (key == nil ? overview.next : nil)
        else { throw key == nil ? TrainingError.sessionAlreadyResolved : TrainingError.unknownSession }
        if let existing = state.activeLive {
            if existing.planId == plan.id && existing.key == session.key { return existing }
            throw TrainingError.liveWorkoutInProgress
        }
        if let status = overview.statusByKey[session.key], status == .completed || status == .skipped {
            throw TrainingError.sessionAlreadyResolved
        }
        let draft = LiveWorkoutDraft(
            version: 1, planId: plan.id, key: session.key, title: session.title, startedAt: now, runningSince: now,
            accumulatedSeconds: 0, index: 0, steps: steps(for: session, restoring: TrainingEngine.latestPartial(plan, key: session.key)),
            restUntil: nil, notes: "", rpe: nil, updatedAt: now)
        state.activeLive = draft
        state.updatedAt = now
        return draft
    }

    private static func mutate(_ state: inout TrainingState, now: Date, _ change: (inout LiveWorkoutDraft) throws -> Void) throws {
        guard var draft = state.activeLive else { throw TrainingError.noLiveWorkout }
        try change(&draft)
        draft.updatedAt = now
        state.activeLive = draft
        state.updatedAt = now
    }

    /// One more rep/set/step done on the current step; starts the rest timer between units.
    static func markUnit(_ state: inout TrainingState, now: Date = Date()) throws {
        try mutate(&state, now: now) { d in
            guard d.steps.indices.contains(d.index), !d.steps[d.index].isComplete else { return }
            if d.steps[d.index].checklist != nil {
                if let next = d.steps[d.index].checklist?.firstIndex(where: { !$0.done }) {
                    d.steps[d.index].checklist?[next].done = true
                }
                d.steps[d.index].done = d.steps[d.index].checklist?.filter(\.done).count ?? 0
            } else {
                d.steps[d.index].done += 1
            }
            let step = d.steps[d.index]
            d.restUntil = step.restSeconds > 0 && !step.isComplete ? now.addingTimeInterval(TimeInterval(step.restSeconds)) : nil
        }
    }

    static func undoUnit(_ state: inout TrainingState, now: Date = Date()) throws {
        try mutate(&state, now: now) { d in
            guard d.steps.indices.contains(d.index), d.steps[d.index].done > 0 else { return }
            if d.steps[d.index].checklist != nil {
                if let last = d.steps[d.index].checklist?.lastIndex(where: { $0.done }) {
                    d.steps[d.index].checklist?[last].done = false
                }
                d.steps[d.index].done = d.steps[d.index].checklist?.filter(\.done).count ?? 0
            } else {
                d.steps[d.index].done -= 1
            }
            d.restUntil = nil
        }
    }

    static func toggleChecklist(_ state: inout TrainingState, stepId: String, itemId: String, now: Date = Date()) throws {
        try mutate(&state, now: now) { d in
            guard let s = d.steps.firstIndex(where: { $0.id == stepId }),
                  let i = d.steps[s].checklist?.firstIndex(where: { $0.id == itemId }) else { return }
            d.steps[s].checklist?[i].done.toggle()
            d.steps[s].done = d.steps[s].checklist?.filter(\.done).count ?? 0
        }
    }

    static func goTo(_ state: inout TrainingState, index: Int, now: Date = Date()) throws {
        try mutate(&state, now: now) { d in
            guard d.steps.indices.contains(index) else { return }
            d.index = index
            d.restUntil = nil
        }
    }

    static func next(_ state: inout TrainingState, now: Date = Date()) throws {
        let index = (state.activeLive?.index ?? 0) + 1
        try goTo(&state, index: min(index, (state.activeLive?.steps.count ?? 1) - 1), now: now)
    }

    static func previous(_ state: inout TrainingState, now: Date = Date()) throws {
        try goTo(&state, index: max(0, (state.activeLive?.index ?? 0) - 1), now: now)
    }

    static func togglePause(_ state: inout TrainingState, now: Date = Date()) throws {
        try mutate(&state, now: now) { d in
            if let since = d.runningSince {
                d.accumulatedSeconds += max(0, now.timeIntervalSince(since))
                d.runningSince = nil
            } else {
                d.runningSince = now
            }
        }
    }

    static func startRest(_ state: inout TrainingState, seconds: Int, now: Date = Date()) throws {
        try mutate(&state, now: now) { d in d.restUntil = now.addingTimeInterval(TimeInterval(min(max(seconds, 5), 600))) }
    }

    static func skipRest(_ state: inout TrainingState, now: Date = Date()) throws {
        try mutate(&state, now: now) { d in d.restUntil = nil }
    }

    static func update(_ state: inout TrainingState, notes: String? = nil, rpe: Int?? = nil, now: Date = Date()) throws {
        if case let .some(.some(value)) = rpe, !(1...10).contains(value) { throw TrainingError.invalidValue("RPE 1–10") }
        try mutate(&state, now: now) { d in
            if let notes { d.notes = String(notes.prefix(2000)) }
            if let rpe { d.rpe = rpe }
        }
    }

    /// Logs Completed when every step is done, otherwise Partial (the session stays current).
    @discardableResult
    static func finish(_ state: inout TrainingState, now: Date = Date(), calendar: Calendar = .current,
                       id: String = UUID().uuidString) throws -> SessionAttempt {
        guard let draft = state.activeLive else { throw TrainingError.noLiveWorkout }
        guard draft.planId == state.activePlanId else { throw TrainingError.unknownSession }
        let minutes = max(1, Int((draft.elapsed(at: now) / 60).rounded()))
        let sets = draft.steps.filter { $0.kind == "strength" }.map { "\($0.title): \($0.done)/\($0.total) เซต" }.joined(separator: "; ")
        let input = AttemptInput(
            status: draft.isComplete ? .completed : .partial, mode: "live", duration: minutes, rpe: draft.rpe,
            repsDone: draft.steps.first { $0.kind == "sprint" }?.done, sets: sets, notes: draft.notes,
            components: draft.steps.map { ComponentProgress(id: $0.id, title: $0.title, kind: $0.kind, done: $0.done, total: $0.total) })
        let attempt = try TrainingEngine.record(&state, key: draft.key, input: input, now: now, calendar: calendar, id: id)
        state.activeLive = nil
        return attempt
    }

    static func cancel(_ state: inout TrainingState, now: Date = Date()) {
        state.activeLive = nil
        state.updatedAt = now
    }
}
