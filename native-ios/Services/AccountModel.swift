import Foundation
import SwiftUI

/// Observable account state for SwiftUI. Session lifecycle rules live in `AuthSessionController`.
@MainActor
final class AccountModel: ObservableObject {
    enum Phase: Equatable { case restoring, signedOut, signedIn }

    @Published private(set) var phase: Phase = .restoring
    @Published private(set) var user: AuthUser?
    /// Signed in with a stored session that could not be refreshed (no network yet).
    @Published private(set) var isOffline = false
    @Published private(set) var pendingEmail: String?
    @Published private(set) var isBusy = false
    @Published var message: String?

    private let controller: AuthSessionController

    init(controller: AuthSessionController) {
        self.controller = controller
    }

    static func live() -> AccountModel {
        let store = KeychainSessionStore()
        // Keychain items survive app deletion; a reinstall must not silently restore an old account.
        let marker = "project100m.keychainInstallMarker"
        if !UserDefaults.standard.bool(forKey: marker) {
            store.clear()
            UserDefaults.standard.set(true, forKey: marker)
        }
        return AccountModel(controller: AuthSessionController(
            client: SupabaseAuthClient(config: .project100m, transport: URLSessionTransport()), store: store))
    }

    static func uiTesting() -> AccountModel {
        AccountModel(controller: AuthSessionController(
            client: SupabaseAuthClient(config: .project100m, transport: OfflineTransport()), store: InMemorySessionStore()))
    }

    var scope: AccountScope { user.map { .user($0.id) } ?? .guest }

    var displayName: String {
        guard let email = user?.email, let name = email.split(separator: "@").first, !name.isEmpty else { return "Athlete" }
        return String(name)
    }

    func restore() async {
        switch await controller.restore() {
        case .signedOut: apply(nil, offline: false)
        case .signedIn(let session): apply(session.user, offline: false)
        case .offline(let session): apply(session.user, offline: true)
        }
    }

    @discardableResult
    func requestCode(email: String) async -> Bool {
        await run {
            try await self.controller.client.sendEmailSignIn(email)
            self.pendingEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
    }

    @discardableResult
    func verify(code: String) async -> Bool {
        guard let email = pendingEmail else { return false }
        return await run {
            let session = try await self.controller.client.verifyEmailCode(email: email, code: code)
            try self.adopt(session)
        }
    }

    /// Completes sign-in from a pasted email link or a `project100m://auth-callback` URL.
    @discardableResult
    func complete(linkText: String) async -> Bool {
        guard let link = AuthLink.parse(linkText) else {
            message = AuthError.unrecognisedLink.errorDescription
            return false
        }
        return await run {
            let session = try await self.controller.client.complete(link)
            try self.adopt(session)
        }
    }

    func cancelPendingCode() {
        pendingEmail = nil
        message = nil
    }

    func signOut() async {
        isBusy = true
        await controller.signOut()
        pendingEmail = nil
        apply(nil, offline: false)
        isBusy = false
    }

    private func adopt(_ session: AuthSession) throws {
        try controller.adopt(session)
        pendingEmail = nil
        apply(session.user, offline: false)
    }

    private func apply(_ user: AuthUser?, offline: Bool) {
        self.user = user
        isOffline = offline
        phase = user == nil ? .signedOut : .signedIn
    }

    private func run(_ work: @escaping () async throws -> Void) async -> Bool {
        isBusy = true
        message = nil
        defer { isBusy = false }
        do {
            try await work()
            return true
        } catch {
            message = (error as? LocalizedError)?.errorDescription ?? "เกิดข้อผิดพลาด ลองใหม่อีกครั้ง"
            return false
        }
    }
}
