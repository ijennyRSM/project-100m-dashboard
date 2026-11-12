import Foundation
import Security

/// Keychain-backed session storage. Items are device-only and readable after first unlock
/// (so a restore can run when the app is relaunched in the background). Tokens never go to
/// UserDefaults, files or logs.
final class KeychainSessionStore: SessionStore {
    struct KeychainError: Error { let status: OSStatus }

    private let service: String
    private let account = "supabase-session"

    init(service: String = "com.project100m.ios.auth") { self.service = service }

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func read() -> AuthSession? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        guard let session = try? TrainingRepository.decoder().decode(AuthSession.self, from: data) else {
            clear() // incompatible or damaged item: discard rather than crash or reuse
            return nil
        }
        return session
    }

    func write(_ session: AuthSession) throws {
        let data = try TrainingRepository.encoder().encode(session)
        let attributes: [String: Any] = [kSecValueData as String: data,
                                         kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        let status = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var add = baseQuery
            add.merge(attributes) { _, new in new }
            let added = SecItemAdd(add as CFDictionary, nil)
            guard added == errSecSuccess else { throw KeychainError(status: added) }
        } else if status != errSecSuccess {
            throw KeychainError(status: status)
        }
    }

    func clear() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}

/// Ephemeral URLSession: no shared cookie or URL cache holds tokens.
struct URLSessionTransport: HTTPTransport {
    let session = URLSession(configuration: .ephemeral)

    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.malformedResponse }
        return (data, http)
    }
}

/// Used by UI testing so automated runs never contact the production auth service.
struct OfflineTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        throw AuthError.network("Network disabled for UI testing")
    }
}
