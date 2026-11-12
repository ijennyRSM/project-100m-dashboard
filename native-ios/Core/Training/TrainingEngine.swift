import Foundation

enum TrainingError: Error, Equatable, LocalizedError {
    case unknownTemplate
    case templateUnavailable
    case noActivePlan
    case unknownSession
    case sessionAlreadyResolved
    case skipNeedsConfirmation
    case liveWorkoutInProgress
    case noLiveWorkout
    case invalidValue(String)

    var errorDescription: String? {
        switch self {
        case .unknownTemplate: return "ไม่พบโปรแกรมนี้"
        case .templateUnavailable: return "โปรแกรมนี้ยังไม่มี prescription ที่ผ่านการทบทวน"
        case .noActivePlan: return "ยังไม่ได้เลือกแผนฝึก"
        case .unknownSession: return "ไม่พบ Session ในแผนปัจจุบัน"
        case .sessionAlreadyResolved: return "Session นี้บันทึกว่าเสร็จหรือข้ามไปแล้ว"
        case .skipNeedsConfirmation: return "การข้าม Session ต้องยืนยันก่อนเสมอ"
        case .liveWorkoutInProgress: return "มี Live Workout ค้างอยู่ ให้จบหรือยกเลิกก่อนเริ่มรายการใหม่"
        case .noLiveWorkout: return "ยังไม่ได้เริ่ม Live Workout"
        case .invalidValue(let field): return "ค่าที่กรอกไม่ถูกต้อง: \(field)"
        }
    }
}

/// Values for a manual (quick) log or the summary of a Live Workout.
struct AttemptInput: Hashable {
    var status: AttemptStatus
    var mode: String = "quick"
    var duration: Int? = nil
    var rpe: Int? = nil
    var repsDone: Int? = nil
    var sets: String = ""
    var notes: String = ""
    var components: [ComponentProgress]? = nil
    /// Required for `.skipped`: the moment the user explicitly confirmed the skip.
    var skipConfirmedAt: Date? = nil
}

/// Pure progression rules. Mirrors the web app: plan order is the generated session order,
/// the latest record per key wins, and `next` is the first session not Completed/Skipped.
/// Calendar dates never advance, expire or skip a session.
enum TrainingEngine {
    static func activePlan(_ state: TrainingState) -> TrainingPlan? {
        state.plans.first { $0.id == state.activePlanId }
    }

    static func overview(_ plan: TrainingPlan) -> PlanOverview {
        let sessions = TrainingCatalog.sessions(for: plan.templateId)
        var latest: [String: AttemptStatus] = [:]
        for record in plan.records { latest[record.key] = record.status }
        let completed = sessions.filter { latest[$0.key] == .completed }.count
        let skipped = sessions.filter { latest[$0.key] == .skipped }.count
        let next = sessions.first { latest[$0.key] != .completed && latest[$0.key] != .skipped }
        return PlanOverview(sessions: sessions, completed: completed, skipped: skipped, total: sessions.count,
                            next: next, statusByKey: latest)
    }

    /// Latest Partial attempt for a session, used to restore completed components.
    static func latestPartial(_ plan: TrainingPlan, key: String) -> SessionAttempt? {
        guard let last = plan.records.last(where: { $0.key == key }), last.status == .partial else { return nil }
        return last
    }

    @discardableResult
    static func startPlan(_ state: inout TrainingState, templateId: String, now: Date = Date(),
                          id: String = UUID().uuidString) throws -> TrainingPlan {
        guard let template = TrainingCatalog.template(templateId) else { throw TrainingError.unknownTemplate }
        guard template.isAvailable else { throw TrainingError.templateUnavailable }
        guard state.activeLive == nil else { throw TrainingError.liveWorkoutInProgress }
        let plan = TrainingPlan(id: id, templateId: templateId, startedAt: now, records: [], source: "native")
        state.plans.append(plan)
        state.activePlanId = plan.id
        state.updatedAt = now
        return plan
    }

    static func selectPlan(_ state: inout TrainingState, planId: String, now: Date = Date()) throws {
        guard state.plans.contains(where: { $0.id == planId }) else { throw TrainingError.noActivePlan }
        guard state.activeLive == nil || state.activeLive?.planId == planId else { throw TrainingError.liveWorkoutInProgress }
        state.activePlanId = planId
        state.updatedAt = now
    }

    /// Appends an attempt to the active plan. Completed advances; Partial keeps the session
    /// current; Skipped advances only with an explicit confirmation timestamp.
    @discardableResult
    static func record(_ state: inout TrainingState, key: String, input: AttemptInput, now: Date = Date(),
                       calendar: Calendar = .current, id: String = UUID().uuidString) throws -> SessionAttempt {
        guard let index = state.plans.firstIndex(where: { $0.id == state.activePlanId }) else { throw TrainingError.noActivePlan }
        let plan = state.plans[index]
        let overview = overview(plan)
        guard overview.sessions.contains(where: { $0.key == key }) else { throw TrainingError.unknownSession }
        if let status = overview.statusByKey[key], status == .completed || status == .skipped {
            throw TrainingError.sessionAlreadyResolved
        }
        if input.status == .skipped && input.skipConfirmedAt == nil { throw TrainingError.skipNeedsConfirmation }
        if let rpe = input.rpe, !(1...10).contains(rpe) { throw TrainingError.invalidValue("RPE 1–10") }
        if let duration = input.duration, !(0...1440).contains(duration) { throw TrainingError.invalidValue("ระยะเวลา") }
        if let reps = input.repsDone, reps < 0 { throw TrainingError.invalidValue("จำนวนเที่ยว") }
        let attempt = SessionAttempt(
            id: id, key: key, at: now, status: input.status, mode: input.mode, date: dayString(now, calendar: calendar),
            duration: input.duration, rpe: input.rpe, repsDone: input.repsDone, sets: String(input.sets.prefix(500)),
            notes: String(input.notes.prefix(2000)), source: "self-reported", components: input.components,
            skipConfirmedAt: input.status == .skipped ? input.skipConfirmedAt : nil)
        state.plans[index].records.append(attempt)
        state.updatedAt = now
        return attempt
    }

    /// Workout history across all plans, newest first.
    static func history(_ state: TrainingState) -> [HistoryEntry] {
        var rows: [HistoryEntry] = []
        for plan in state.plans {
            let titles = Dictionary(TrainingCatalog.sessions(for: plan.templateId).map { ($0.key, $0.title) }, uniquingKeysWith: { a, _ in a })
            let name = TrainingCatalog.template(plan.templateId)?.name ?? plan.templateId
            for record in plan.records {
                rows.append(HistoryEntry(attempt: record, sessionTitle: titles[record.key] ?? record.key, templateName: name, planId: plan.id))
            }
        }
        return rows.sorted { $0.attempt.at > $1.attempt.at }
    }

    static func dayString(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}
