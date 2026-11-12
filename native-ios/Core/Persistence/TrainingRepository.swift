import Foundation

/// Storage partition. Guest data and each authenticated Supabase user live in separate
/// directories; nothing is merged between partitions without an explicit user action.
enum AccountScope: Hashable {
    case guest
    case user(String)

    /// Directory name. User IDs must be UUIDs, which also prevents path traversal.
    var directoryName: String? {
        switch self {
        case .guest: return "guest"
        case .user(let id):
            guard let uuid = UUID(uuidString: id) else { return nil }
            return "user-" + uuid.uuidString.lowercased()
        }
    }
}

enum RepositoryLoadOutcome: Equatable {
    case fresh
    case loaded
    /// The stored document could not be used; it was moved aside (never deleted).
    case recovered(reason: String, backupFile: String)
}

/// File-based JSON repository for one account's `TrainingState`.
///
/// Writes are atomic (temp file + rename) and, on iOS, protected until first unlock.
/// Unreadable or newer-schema documents are preserved beside the store and a fresh state is
/// returned, so a corrupt file can never crash launch or be silently overwritten.
final class TrainingRepository {
    let directory: URL
    var fileURL: URL { directory.appendingPathComponent("training.json") }
    private let fileManager: FileManager
    /// Set when an unusable document could not be moved aside; saving would destroy it.
    private(set) var writeBlocked = false

    init(directory: URL, fileManager: FileManager = .default) {
        self.directory = directory
        self.fileManager = fileManager
    }

    static func forScope(_ scope: AccountScope, root: URL) -> TrainingRepository? {
        guard let name = scope.directoryName else { return nil }
        return TrainingRepository(directory: root.appendingPathComponent("accounts", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true))
    }

    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    func load(now: Date = Date()) -> (TrainingState, RepositoryLoadOutcome) {
        guard let data = try? Data(contentsOf: fileURL) else { return (.empty(now: now), .fresh) }
        struct Header: Decodable { var schemaVersion: Int? }
        let version = (try? JSONDecoder().decode(Header.self, from: data))?.schemaVersion
        if let version, version > TrainingState.currentSchema {
            return (.empty(now: now), quarantine(reason: "schema \(version) is newer than supported \(TrainingState.currentSchema)", now: now))
        }
        do {
            var state = try Self.decoder().decode(TrainingState.self, from: data)
            state = Self.migrate(state)
            if let active = state.activePlanId, !state.plans.contains(where: { $0.id == active }) {
                state.activePlanId = state.plans.last?.id
            }
            if let live = state.activeLive, !state.plans.contains(where: { $0.id == live.planId }) {
                state.activeLive = nil
            }
            return (state, .loaded)
        } catch {
            return (.empty(now: now), quarantine(reason: "unreadable training data", now: now))
        }
    }

    /// Schema migrations run here, in order, on decoded documents (v1 is current).
    static func migrate(_ state: TrainingState) -> TrainingState {
        var state = state
        if state.schemaVersion < 1 { state.schemaVersion = 1 }
        return state
    }

    func save(_ state: TrainingState) throws {
        if writeBlocked { throw CocoaError(.fileWriteNoPermission) }
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try Self.encoder().encode(state)
        #if os(iOS)
        try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        #else
        try data.write(to: fileURL, options: [.atomic])
        #endif
    }

    /// Removes this partition's data (used only for explicit user deletion and test resets).
    func deleteAll() throws {
        if fileManager.fileExists(atPath: directory.path) { try fileManager.removeItem(at: directory) }
    }

    private func quarantine(reason: String, now: Date) -> RepositoryLoadOutcome {
        let stamp = Int(now.timeIntervalSince1970)
        let backup = directory.appendingPathComponent("training.unusable-\(stamp).json")
        do {
            if fileManager.fileExists(atPath: backup.path) { try fileManager.removeItem(at: backup) }
            try fileManager.moveItem(at: fileURL, to: backup)
            return .recovered(reason: reason, backupFile: backup.lastPathComponent)
        } catch {
            writeBlocked = true
            return .recovered(reason: reason + "; backup move failed: \(error.localizedDescription)", backupFile: "")
        }
    }
}
