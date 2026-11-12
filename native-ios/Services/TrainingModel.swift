import Foundation
import SwiftUI

/// Observable, offline-first training store for the signed-in account (or guest).
/// Every mutation is applied to a copy, saved atomically, then published, so the UI never
/// shows progress that is not on disk.
@MainActor
final class TrainingModel: ObservableObject {
    @Published private(set) var state = TrainingState.empty()
    @Published private(set) var scope: AccountScope?
    @Published var notice: String?
    @Published var errorMessage: String?
    /// True when signed in to an empty account while this device holds Guest training data.
    @Published private(set) var guestImportAvailable = false

    private let root: URL
    private var repository: TrainingRepository?

    init(root: URL) {
        self.root = root
    }

    static func liveRoot() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("PROJECT100M", isDirectory: true)
    }

    static func uiTestingRoot(reset: Bool) -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("PROJECT100M-UITests", isDirectory: true)
        if reset { try? FileManager.default.removeItem(at: root) }
        return root
    }

    var isLoaded: Bool { scope != nil }
    var activePlan: TrainingPlan? { TrainingEngine.activePlan(state) }
    var overview: PlanOverview? { activePlan.map(TrainingEngine.overview) }
    var activeTemplate: PlanTemplate? { activePlan.flatMap { TrainingCatalog.template($0.templateId) } }
    var history: [HistoryEntry] { TrainingEngine.history(state) }
    var live: LiveWorkoutDraft? { state.activeLive }

    func switchScope(_ newScope: AccountScope) {
        guard newScope != scope else { return }
        guard let repo = TrainingRepository.forScope(newScope, root: root) else {
            errorMessage = "บัญชีนี้มีรหัสผู้ใช้ไม่ถูกต้อง จึงไม่เปิดข้อมูลในเครื่อง"
            return
        }
        let (loaded, outcome) = repo.load()
        repository = repo
        state = loaded
        scope = newScope
        errorMessage = nil
        guestImportAvailable = false
        if case .user = newScope, loaded.plans.isEmpty, let guest = TrainingRepository.forScope(.guest, root: root) {
            let (guestState, guestOutcome) = guest.load()
            guestImportAvailable = guestOutcome == .loaded && !guestState.plans.isEmpty
        }
        if case .recovered(let reason, let backup) = outcome {
            notice = "ข้อมูลฝึกเดิมในเครื่องเปิดไม่ได้ (\(reason)) จึงเริ่มใหม่ และเก็บไฟล์เดิมไว้เป็น \(backup.isEmpty ? "ไฟล์เดิม" : backup)"
        } else {
            notice = nil
        }
    }

    /// Copies (never moves or merges) this device's Guest training into an empty account
    /// partition, only after explicit user confirmation. Guest data stays in place.
    @discardableResult
    func importGuestData() -> Bool {
        guard case .user = scope, state.plans.isEmpty, state.activeLive == nil,
              let guest = TrainingRepository.forScope(.guest, root: root) else { return false }
        let (guestState, outcome) = guest.load()
        guard outcome == .loaded, !guestState.plans.isEmpty else { return false }
        let copied = perform { state in
            state = guestState
            state.updatedAt = Date()
        }
        if copied { guestImportAvailable = false }
        return copied
    }

    /// Deletes this device's training files for the current scope (explicit user action only).
    func deleteLocalData(for deletedScope: AccountScope) {
        try? TrainingRepository.forScope(deletedScope, root: root)?.deleteAll()
        if deletedScope == scope {
            state = .empty()
        }
    }

    @discardableResult
    func perform(_ change: (inout TrainingState) throws -> Void) -> Bool {
        guard let repository else {
            errorMessage = "ข้อมูลฝึกยังไม่พร้อม"
            return false
        }
        var copy = state
        do {
            try change(&copy)
            try repository.save(copy)
            state = copy
            errorMessage = nil
            return true
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "บันทึกข้อมูลในเครื่องไม่สำเร็จ"
            return false
        }
    }

    // MARK: Convenience actions

    @discardableResult
    func startPlan(_ templateId: String) -> Bool {
        perform { try TrainingEngine.startPlan(&$0, templateId: templateId) }
    }

    @discardableResult
    func selectPlan(_ planId: String) -> Bool {
        perform { try TrainingEngine.selectPlan(&$0, planId: planId) }
    }

    @discardableResult
    func log(_ key: String, _ input: AttemptInput) -> Bool {
        perform { try TrainingEngine.record(&$0, key: key, input: input) }
    }

    @discardableResult
    func startLive(key: String? = nil) -> Bool {
        perform { try LiveWorkoutEngine.start(&$0, key: key) }
    }
}
