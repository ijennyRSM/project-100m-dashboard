import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Public client configuration. The publishable key is designed to ship in clients (it is
/// already public in the website's `cloud-config.js`). Never place a secret or service_role
/// key here: access is limited by Supabase Auth and owner-scoped RLS.
struct SupabaseConfig: Equatable {
    let url: URL
    let publishableKey: String
    /// Custom-scheme callback. Only used by Supabase if the owner adds it to the Auth
    /// redirect allow-list; otherwise Supabase falls back to the website Site URL.
    let redirectURL: URL

    static let project100m = SupabaseConfig(
        url: URL(string: "https://rbryddekjwytcoqqgcgu.supabase.co")!,
        publishableKey: "sb_publishable_WU-Pmqr6a8DIcPvGZC3yBw_QT-lvasj",
        redirectURL: URL(string: "project100m://auth-callback")!)
}

struct AuthUser: Codable, Equatable {
    var id: String
    var email: String?
}

/// Session material. Persist only in the Keychain.
struct AuthSession: Codable, Equatable {
    var accessToken: String
    var refreshToken: String
    var expiresAt: Date
    var user: AuthUser

    func needsRefresh(now: Date, leeway: TimeInterval = 120) -> Bool {
        expiresAt.timeIntervalSince(now) <= leeway
    }
}

enum AuthError: Error, Equatable, LocalizedError {
    case invalidEmail
    case invalidCode
    case unrecognisedLink
    case network(String)
    /// The server rejected the request (4xx). `code` is the Supabase error code when present.
    case rejected(status: Int, code: String?, message: String)
    case server(status: Int)
    case malformedResponse

    /// Session can no longer be refreshed and must be discarded.
    var invalidatesSession: Bool {
        if case .rejected(let status, let code, _) = self {
            return status == 400 || status == 401 || status == 403 || code == "refresh_token_not_found"
                || code == "refresh_token_already_used" || code == "session_not_found"
        }
        return false
    }

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "กรุณากรอกอีเมลให้ถูกต้อง"
        case .invalidCode: return "กรุณากรอกรหัส 6–8 หลักจากอีเมล"
        case .unrecognisedLink: return "ลิงก์นี้ไม่ใช่ลิงก์เข้าสู่ระบบของ PROJECT 100M"
        case .network: return "เชื่อมต่อเครือข่ายไม่ได้ ลองใหม่เมื่อออนไลน์"
        case .rejected(let status, let code, let message):
            switch code {
            case "otp_disabled", "signup_disabled", "user_not_found":
                return "ไม่พบบัญชีนี้ สร้างบัญชีผ่านเว็บไซต์ PROJECT 100M ก่อน"
            case "otp_expired": return "รหัสหรือลิงก์หมดอายุหรือถูกใช้แล้ว ขอรหัสใหม่อีกครั้ง"
            case "over_email_send_rate_limit", "over_request_rate_limit":
                return "ขอรหัสบ่อยเกินไป กรุณารอสักครู่แล้วลองใหม่"
            default: return message.isEmpty ? "คำขอถูกปฏิเสธ (\(status))" : message
            }
        case .server(let status): return "เซิร์ฟเวอร์ไม่พร้อม (\(status)) ลองใหม่ภายหลัง"
        case .malformedResponse: return "ข้อมูลตอบกลับไม่ถูกต้อง"
        }
    }
}

/// Network seam so the client is testable without a live Supabase project.
protocol HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

/// Result of parsing a sign-in link pasted by the user or delivered by the URL scheme.
enum AuthLink: Equatable {
    case tokenHash(hash: String, type: String)
    case tokens(access: String, refresh: String, expiresIn: TimeInterval?)
    case error(String)

    /// Accepts the Supabase `/auth/v1/verify?token=…&type=…` email link, a
    /// `token_hash`/`type` link, or a redirect carrying `#access_token=…&refresh_token=…`.
    static func parse(_ text: String, config: SupabaseConfig = .project100m) -> AuthLink? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let components = URLComponents(string: trimmed), components.scheme != nil else { return nil }
        var values: [String: String] = [:]
        for item in components.queryItems ?? [] { values[item.name] = item.value ?? "" }
        if let fragment = components.fragment, var inner = URLComponents(string: "x:") {
            inner.percentEncodedQuery = fragment
            for item in inner.queryItems ?? [] { values[item.name] = item.value ?? "" }
        }
        if let description = values["error_description"] ?? values["error"] { return .error(description) }
        if let access = values["access_token"], let refresh = values["refresh_token"], !access.isEmpty, !refresh.isEmpty {
            return .tokens(access: access, refresh: refresh, expiresIn: values["expires_in"].flatMap(TimeInterval.init))
        }
        let allowed: Set<String> = ["magiclink", "email", "signup"]
        if let hash = values["token_hash"], !hash.isEmpty {
            let type = values["type"] ?? "email"
            return allowed.contains(type) ? .tokenHash(hash: hash, type: type == "magiclink" ? "email" : type) : nil
        }
        if components.host == config.url.host, components.path.hasSuffix("/auth/v1/verify"),
           let token = values["token"], !token.isEmpty {
            let type = values["type"] ?? "magiclink"
            return allowed.contains(type) ? .tokenHash(hash: token, type: type == "magiclink" ? "email" : type) : nil
        }
        return nil
    }
}

/// Minimal Supabase Auth (GoTrue) REST client for passwordless email sign-in, matching the
/// website's `signInWithOtp` account system (same users; no second account system).
struct SupabaseAuthClient {
    let config: SupabaseConfig
    let transport: HTTPTransport
    var now: () -> Date = Date.init

    static func isValidEmail(_ email: String) -> Bool {
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        return email.count <= 254 && parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
            && !parts[1].hasPrefix(".") && !parts[1].hasSuffix(".") && !email.contains(" ")
    }

    /// Sends the email sign-in message. `create_user` is false: native signs in existing
    /// PROJECT 100M accounts only; accounts are created on the website.
    func sendEmailSignIn(_ email: String) async throws {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard Self.isValidEmail(email) else { throw AuthError.invalidEmail }
        _ = try await post("otp", query: [URLQueryItem(name: "redirect_to", value: config.redirectURL.absoluteString)],
                           body: ["email": email, "create_user": false])
    }

    func verifyEmailCode(email: String, code: String) async throws -> AuthSession {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let code = code.filter { !$0.isWhitespace }
        guard Self.isValidEmail(email) else { throw AuthError.invalidEmail }
        guard (6...8).contains(code.count), code.allSatisfy(\.isNumber) else { throw AuthError.invalidCode }
        return try session(from: try await post("verify", body: ["type": "email", "email": email, "token": code]))
    }

    func complete(_ link: AuthLink) async throws -> AuthSession {
        switch link {
        case .error(let message): throw AuthError.rejected(status: 400, code: nil, message: message)
        case .tokenHash(let hash, let type):
            return try session(from: try await post("verify", body: ["type": type, "token_hash": hash]))
        case .tokens(let access, let refresh, let expiresIn):
            let user = try await fetchUser(accessToken: access)
            return AuthSession(accessToken: access, refreshToken: refresh,
                               expiresAt: now().addingTimeInterval(expiresIn ?? 3600), user: user)
        }
    }

    func refresh(_ session: AuthSession) async throws -> AuthSession {
        try self.session(from: try await post("token", query: [URLQueryItem(name: "grant_type", value: "refresh_token")],
                                              body: ["refresh_token": session.refreshToken]))
    }

    func fetchUser(accessToken: String) async throws -> AuthUser {
        var request = URLRequest(url: endpoint("user", query: []))
        request.httpMethod = "GET"
        headers(&request, bearer: accessToken)
        let json = try await perform(request)
        guard let id = json["id"] as? String else { throw AuthError.malformedResponse }
        return AuthUser(id: id, email: json["email"] as? String)
    }

    /// Ends this device's session only (`scope=local`), leaving the website signed in.
    func signOut(_ session: AuthSession) async throws {
        var request = URLRequest(url: endpoint("logout", query: [URLQueryItem(name: "scope", value: "local")]))
        request.httpMethod = "POST"
        headers(&request, bearer: session.accessToken)
        _ = try await perform(request)
    }

    // MARK: - Plumbing

    func endpoint(_ path: String, query: [URLQueryItem]) -> URL {
        var components = URLComponents(url: config.url.appendingPathComponent("auth/v1/" + path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        return components.url!
    }

    private func headers(_ request: inout URLRequest, bearer: String? = nil) {
        request.setValue(config.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let bearer { request.setValue("Bearer " + bearer, forHTTPHeaderField: "Authorization") }
        request.timeoutInterval = 20
    }

    private func post(_ path: String, query: [URLQueryItem] = [], body: [String: Any]) async throws -> [String: Any] {
        var request = URLRequest(url: endpoint(path, query: query))
        request.httpMethod = "POST"
        headers(&request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await perform(request)
    }

    private func perform(_ request: URLRequest) async throws -> [String: Any] {
        let result: (Data, HTTPURLResponse)
        do { result = try await transport.send(request) } catch let error as AuthError { throw error } catch {
            throw AuthError.network(error.localizedDescription)
        }
        let (data, response) = result
        let json = (data.isEmpty ? nil : try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        switch response.statusCode {
        case 200..<300: return json
        case 400..<500:
            let code = (json["error_code"] as? String) ?? (json["code"] as? String) ?? (json["error"] as? String)
            let message = (json["msg"] as? String) ?? (json["error_description"] as? String) ?? (json["message"] as? String) ?? ""
            throw AuthError.rejected(status: response.statusCode, code: code, message: message)
        default: throw AuthError.server(status: response.statusCode)
        }
    }

    static func number(_ value: Any?) -> Double? {
        if let value = value as? Double { return value }
        if let value = value as? Int { return Double(value) }
        if let value = value as? NSNumber { return value.doubleValue }
        return nil
    }

    func session(from json: [String: Any]) throws -> AuthSession {
        guard let access = json["access_token"] as? String, let refresh = json["refresh_token"] as? String,
              let user = json["user"] as? [String: Any], let id = user["id"] as? String else { throw AuthError.malformedResponse }
        let expiresAt: Date
        if let at = Self.number(json["expires_at"]) {
            expiresAt = Date(timeIntervalSince1970: at)
        } else {
            expiresAt = now().addingTimeInterval(Self.number(json["expires_in"]) ?? 3600)
        }
        return AuthSession(accessToken: access, refreshToken: refresh, expiresAt: expiresAt,
                           user: AuthUser(id: id, email: user["email"] as? String))
    }
}

/// Secure storage seam: Keychain on device, in-memory in tests and UI testing.
protocol SessionStore: AnyObject {
    func read() -> AuthSession?
    func write(_ session: AuthSession) throws
    func clear()
}

final class InMemorySessionStore: SessionStore {
    var session: AuthSession?
    init(_ session: AuthSession? = nil) { self.session = session }
    func read() -> AuthSession? { session }
    func write(_ session: AuthSession) throws { self.session = session }
    func clear() { session = nil }
}

/// Session lifecycle independent of UI: restore, persist, refresh and local sign-out.
final class AuthSessionController {
    enum Restore: Equatable {
        case signedOut
        case signedIn(AuthSession)
        /// Kept signed in offline with a stored session that could not be refreshed yet.
        case offline(AuthSession)
    }

    let client: SupabaseAuthClient
    let store: SessionStore

    init(client: SupabaseAuthClient, store: SessionStore) {
        self.client = client
        self.store = store
    }

    func restore() async -> Restore {
        guard let saved = store.read() else { return .signedOut }
        guard saved.needsRefresh(now: client.now()) else { return .signedIn(saved) }
        do {
            let fresh = try await client.refresh(saved)
            try? store.write(fresh)
            return .signedIn(fresh)
        } catch let error as AuthError where error.invalidatesSession {
            store.clear()
            return .signedOut
        } catch {
            return .offline(saved)
        }
    }

    func adopt(_ session: AuthSession) throws {
        try store.write(session)
    }

    /// Always removes local session material, even when the network call fails.
    func signOut() async {
        if let saved = store.read() { try? await client.signOut(saved) }
        store.clear()
    }
}
