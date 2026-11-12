import Foundation

/// Domain models for offline-first training. JSON field names intentionally match the
/// legacy web payload v2 (`templateId`, `startedAt`, `records`, `key`, `status`, ...) so a
/// later reviewed import/sync adapter can map plans and records without renaming.

enum SessionKind: String, Codable, Hashable {
    case sprint, easy, strength, walk
}

struct SprintPrescription: Codable, Hashable {
    var reps: Int
    var meters: Int
    var effort: String
}

struct StrengthExercise: Codable, Hashable {
    var name: String
    var sets: Int
    var reps: String
}

/// Session components ("exercises" in the web payload).
struct SessionComponents: Codable, Hashable {
    var sprint: SprintPrescription?
    var duration: Int?
    var strength: [StrengthExercise]?
}

/// One generated, ordered session of a plan template. Keys are `w<block>-<slot>` as on the web.
struct TrainingSession: Codable, Hashable, Identifiable {
    var key: String
    var block: Int
    var slot: Int
    var title: String
    var kind: SessionKind
    var summary: String
    var details: String
    var components: SessionComponents
    var minutes: Int
    var id: String { key }
}

/// A program definition in the training library.
struct PlanTemplate: Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let blocks: Int
    let description: String
    let symbol: String
    /// False when no reviewed prescription exists yet; such a template cannot be started.
    let isAvailable: Bool
    var availabilityNote: String? = nil
}

enum AttemptStatus: String, Codable, Hashable, CaseIterable {
    case completed, partial, skipped
}

/// Per-component progress captured by Live Workout (warm-up, sprint reps, strength sets...).
struct ComponentProgress: Codable, Hashable, Identifiable {
    var id: String
    var title: String
    var kind: String
    var done: Int
    var total: Int
}

/// Session attempt / workout log. Append-only: corrections add a new record.
struct SessionAttempt: Codable, Hashable, Identifiable {
    var id: String
    var key: String
    var at: Date
    var status: AttemptStatus
    /// "live" (Live Workout) or "quick" (manual log).
    var mode: String
    /// Local calendar day `yyyy-MM-dd` the user trained. Never used for progression.
    var date: String
    var duration: Int?
    var rpe: Int?
    var repsDone: Int?
    var sets: String
    var notes: String
    var source: String
    var components: [ComponentProgress]?
    var skipConfirmedAt: Date?
}

/// An enrolled plan. `source` distinguishes native enrolment from any future reviewed import.
struct TrainingPlan: Codable, Hashable, Identifiable {
    var id: String
    var templateId: String
    var startedAt: Date
    var records: [SessionAttempt]
    var source: String
}

/// Derived workout progress for one plan.
struct PlanOverview: Hashable {
    var sessions: [TrainingSession]
    var completed: Int
    var skipped: Int
    var total: Int
    var next: TrainingSession?
    /// Latest record per session key (web semantics: the latest record wins).
    var statusByKey: [String: AttemptStatus]
    var percent: Int { total == 0 ? 0 : Int((Double(completed + skipped) / Double(total) * 100).rounded()) }
    var isFinished: Bool { next == nil && total > 0 }
}

/// One row of workout history.
struct HistoryEntry: Hashable, Identifiable {
    var attempt: SessionAttempt
    var sessionTitle: String
    var templateName: String
    var planId: String
    var id: String { attempt.id }
}

/// The whole per-account local training document.
struct TrainingState: Codable, Hashable {
    static let currentSchema = 1
    var schemaVersion: Int
    var plans: [TrainingPlan]
    var activePlanId: String?
    var activeLive: LiveWorkoutDraft?
    var updatedAt: Date

    static func empty(now: Date = Date()) -> TrainingState {
        TrainingState(schemaVersion: currentSchema, plans: [], activePlanId: nil, activeLive: nil, updatedAt: now)
    }
}
